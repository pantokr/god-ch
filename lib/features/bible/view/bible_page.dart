import '../../../core/widgets/toast.dart';
import '../../../core/widgets/app_loader.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/format.dart';
import '../../../core/icons.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/create_fab.dart';
import '../../../core/widgets/refresh_scope.dart';
import '../../../core/widgets/sort_pad.dart';
import '../../../core/widgets/stat_icons.dart';
import '../../../core/widgets/thumbnail_avatar.dart';
import '../../../data/models/permission.dart';
import '../../../data/models/affiliation.dart';
import '../../../data/models/church_content.dart';
import '../../../data/models/church_features.dart';
import '../../../data/models/devotion_settings.dart';
import '../../../data/models/member.dart';
import '../../home/view/content_widgets.dart';
import '../../home/view/feature_gate.dart';
import '../../home/view_model/affiliation_choice.dart';
import '../view_model/devotions_view_model.dart';
import 'devotion_form.dart';

/// 말씀묵상: 최근 글쓴이 · 검색 · 정렬 영역과, 각진 카드가 간격을 두고 이어지는 목록.
/// 카드에는 글쓴이와 묵상 미리보기가 있고 (말씀 본문은 없다), 오른쪽 가장자리에 조회수와 좋아요가 보인다.
/// 카드를 누르면 말씀 · 묵상 · 반응 · 댓글이 분리된 카드로 열린다 ([DevotionDetailPage]).
/// 글을 올리는 것은 교역자 · 교회 운영자다.
class BiblePage extends StatelessWidget {
  const BiblePage({super.key, required this.me, required this.choice});

  final Member me;
  final AffiliationChoice choice;

  @override
  Widget build(BuildContext context) {
    return FeatureGate(
      feature: PageFeature.word,
      me: me,
      choice: choice,
      builder: (context, _) => RefreshScope(
        builder: (context, generation, refresh) =>
            ViewModelBuilder<DevotionsViewModel>(
              key: ValueKey('bible/${me.churchId}/$generation'),
              create: (context) => DevotionsViewModel(
                AppScope.read(context).contents,
                me.churchId,
                authorName: me.name,
                authorPhotoUrl: me.photoUrl,
                affiliations: AppScope.read(context).affiliations
                    .affiliations(me.churchId),
                includePrivate: me.can(Permission.devotionViewPrivate),
              ),
              builder: (context, vm) => Stack(
                fit: StackFit.expand,
                children: [
                  SingleChildScrollView(
                    // 오른쪽 아래 버튼에 마지막 줄이 가리지 않게 아래를 비운다.
                    padding: const EdgeInsets.only(bottom: CreateFab.clearance),
                    child: PageFrame(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          PageTitle(
                            gap: PageTitle.panelGap,
                            title: '말씀묵상',
                            description: '교역자가 올린 말씀과 묵상을 읽고, 내 묵상을 댓글로 남깁니다. 소속별로 모아 보거나 조회순·좋아요순으로 정렬할 수 있어요.',
                          ),
                          StreamBuilder<List<Affiliation>>(
                            stream: vm.affiliations,
                            builder: (context, affSnap) =>
                                StreamBuilder<List<ChurchContent>>(
                                  stream: vm.items,
                                  builder: (context, snap) {
                                    if (snap.hasError) {
                                      return EmptyHint(
                                        '불러오지 못했습니다\n${snap.error}',
                                      );
                                    }
                                    final all = snap.data;
                                    final affiliations = affSnap.data;
                                    if (all == null ||
                                        (affiliations == null &&
                                            !affSnap.hasError)) {
                                      return const Padding(
                                        padding: EdgeInsets.all(48),
                                        child: Center(child: AppLoader()),
                                      );
                                    }
                                    final items = vm.apply(all);
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _FilterPanel(
                                          vm: vm,
                                          affiliations: me.visibleAffiliations(
                                            affiliations ?? const [],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        // 패널 영역과 목록 영역을 가르는 선, 그 아래 목록 윗부분 오른쪽에 새로고침.
                                        Divider(
                                          height: 1,
                                          color: context.palette.border,
                                        ),
                                        // 최근 글쓴이 프로필은 왼쪽, 새로고침은 그 맞은편 오른쪽에 둔다.
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _RecentAuthors(
                                                visible: vm.settings.showAuthor,
                                                authors:
                                                    DevotionsViewModel.recentAuthors(
                                                      all,
                                                    ),
                                              ),
                                            ),
                                            refresh,
                                          ],
                                        ),
                                        if (items.isEmpty)
                                          EmptyHint(
                                            all.isEmpty ? '말씀 없음' : '검색 결과 없음',
                                          )
                                        else
                                          for (final c in items)
                                            _DevotionCard(
                                              content: c,
                                              me: me,
                                              settings: vm.settings,
                                            ),
                                      ],
                                    );
                                  },
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (me.can(Permission.devotionWrite))
                    Positioned(
                      right: 16,
                      bottom: 16 + MediaQuery.paddingOf(context).bottom,
                      child: CreateFab(
                        label: '말씀 추가',
                        onTap: vm.busy ? null : () => _add(context, vm),
                      ),
                    ),
                ],
              ),
            ),
      ),
    );
  }

  Future<void> _add(BuildContext context, DevotionsViewModel vm) async {
    final result = await showDevotionForm(
      context,
      churchId: me.churchId,
      visible: me.sees,
    );
    if (result == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final inset = MediaQuery.paddingOf(context).bottom;
    final ok = await vm.save(
      title: result.title,
      body: result.body,
      meditation: result.meditation,
      date: result.date,
      affiliationId: result.affiliationId,
      isPrivate: result.isPrivate,
    );
    if (ok) {
      showToastOn(messenger, '추가되었습니다', bottom: inset);
    } else if (vm.error != null) {
      messenger.showSnackBar(SnackBar(content: Text(vm.error!)));
    }
  }
}

/// 최근 글을 쓴 사람들: "7일간 [프로필 사진들] 의 사람들이 묵상했습니다" 한 줄.
/// 사진은 작게 겹쳐 놓고 5명을 넘으면 "+N"으로 줄인다.
class _RecentAuthors extends StatelessWidget {
  const _RecentAuthors({required this.authors, this.visible = true});

  /// 최근 7일 안에 글을 쓴 사람들 (최신 글 순서, 중복 없음).
  final List<ChurchContent> authors;

  /// 글쓴이 공개 설정이 꺼져 있으면 숨긴다.
  final bool visible;

  /// 프로필 사진으로 보이는 최대 인원. 넘으면 나머지는 "+N"으로 줄인다.
  static const maxShown = 5;

  static const _radius = 11.0;
  static const _ring = 1.5;
  static const _step = 17.0;

  @override
  Widget build(BuildContext context) {
    if (!visible || authors.isEmpty) return const SizedBox.shrink();
    final palette = context.palette;
    const size = (_radius + _ring) * 2;
    final shown = authors.take(maxShown).toList();
    final more = authors.length - shown.length;
    final count = shown.length + (more > 0 ? 1 : 0);
    final text = TextStyle(color: palette.muted, fontSize: 12);
    Widget ring(Widget child) => DecoratedBox(
      decoration: BoxDecoration(shape: BoxShape.circle, color: palette.surface),
      child: Padding(padding: const EdgeInsets.all(_ring), child: child),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text('7일간', style: text),
          const SizedBox(width: 8),
          SizedBox(
            width: (count - 1) * _step + size,
            height: size,
            child: Stack(
              children: [
                for (var i = 0; i < shown.length; i++)
                  Positioned(
                    left: i * _step,
                    child: Tooltip(
                      message: shown[i].authorName,
                      child: ring(
                        ThumbnailAvatar(
                          name: shown[i].authorName,
                          url: shown[i].authorPhotoUrl,
                          radius: _radius,
                        ),
                      ),
                    ),
                  ),
                if (more > 0)
                  Positioned(
                    left: shown.length * _step,
                    child: Tooltip(
                      message: '이번 주 글쓴이 $more명 더',
                      child: ring(
                        CircleAvatar(
                          radius: _radius,
                          backgroundColor: palette.brand.withValues(
                            alpha: 0.12,
                          ),
                          child: Text(
                            '+$more',
                            style: TextStyle(
                              color: palette.brand,
                              fontWeight: FontWeight.w800,
                              fontSize: 9.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '의 사람들이 묵상했습니다',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text,
            ),
          ),
        ],
      ),
    );
  }
}

/// 검색 · 정렬 영역.
class _FilterPanel extends StatefulWidget {
  const _FilterPanel({required this.vm, required this.affiliations});

  final DevotionsViewModel vm;
  final List<Affiliation> affiliations;

  @override
  State<_FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<_FilterPanel> {
  late final _search = TextEditingController(text: widget.vm.query);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    return SortPad(
      header: TextField(
        controller: _search,
        onChanged: vm.setQuery,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: '검색',
          isDense: true,
          prefixIcon: const Icon(AppIcons.magnifyingGlass, size: 18),
          suffixIcon: vm.query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(AppIcons.x, size: 18),
                  onPressed: () {
                    _search.clear();
                    vm.setQuery('');
                  },
                ),
        ),
      ),
      groups: [
        if (widget.affiliations.isNotEmpty)
          PadGroup(label: '소속', [
            for (final a in [null, ...widget.affiliations])
              PadOption(
                a?.name ?? '전체',
                selected: vm.affiliationId == a?.id,
                onTap: () => vm.setAffiliation(a?.id),
              ),
          ]),
        PadGroup(label: '정렬 순서', [
          for (final s in DevotionSort.values)
            PadOption(
              s.label,
              selected: vm.sort == s,
              onTap: () => vm.setSort(s),
            ),
        ]),
      ],
    );
  }
}

/// 각진 카드 한 장: 말씀 제목과 날짜, 글쓴이(프로필 · 이름), 묵상 미리보기, 가장자리의 조회수와 좋아요. 말씀 본문은 목록에 싣지 않는다.
class _DevotionCard extends StatelessWidget {
  const _DevotionCard({
    required this.content,
    required this.me,
    required this.settings,
  });

  final ChurchContent content;
  final Member me;
  final DevotionSettings settings;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final c = content;
    // 앱 개발자는 교인이 아니라 읽음 표시가 없다.
    final read = !me.isOperatorView && c.readBy.contains(me.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: () => context.push(Routes.devotion(me.churchId, c.id)),
        borderRadius: BorderRadius.circular(4),
        child: Ink(
          // 읽음 바는 카드 맨 위 가장자리에 붙으므로 위쪽 여백은 바 아래에서 시작한다.
          padding: EdgeInsets.fromLTRB(16, read ? 0 : 16, 16, 16),
          decoration: BoxDecoration(
            color: palette.surface,
            border: Border.all(color: context.cardEdge),
            borderRadius: BorderRadius.circular(4),
          ),
          // 위에서 아래로: 제목 → 묵상(카드 너비 전부) → 좋아요 · 조회수(오른쪽) → 글쓴이(왼쪽)와 날짜(맞은편 오른쪽).
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 읽은 글은 카드 맨 위에 카드 너비를 전부 차지하는 바가 붙고, 가운데에 흰 글씨 "읽음"이 있다 (바는 짙은 회색).
              if (read)
                LayoutBuilder(
                  builder: (context, box) => SizedBox(
                    height: 26,
                    child: OverflowBox(
                      // 카드 안쪽 좌우 여백(16)까지 덮어 카드 가장자리에서 가장자리까지 채운다.
                      minWidth: box.maxWidth + 32,
                      maxWidth: box.maxWidth + 32,
                      child: Container(
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: palette.muted,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3),
                          ),
                        ),
                        child: Text(
                          '읽음',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (read) const SizedBox(height: 14),
              Row(
                children: [
                  if (c.isPrivate) ...[
                    Icon(AppIcons.lock, size: 14, color: palette.muted),
                    const SizedBox(width: 4),
                  ],
                  // 안 읽은 글은 제목 앞에 강조색 점이 붙는다.
                  if (!me.isOperatorView && !read) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: palette.accent,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      c.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              if (c.meditation.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  c.meditation,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: StatIcons(
                  horizontal: true,
                  showViews: settings.showViews,
                  views: c.views,
                  likes: c.likes,
                  liked: c.likedBy.contains(me.id),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (c.authorName.isNotEmpty && settings.showAuthor) ...[
                    ThumbnailAvatar(
                      name: c.authorName,
                      url: c.authorPhotoUrl,
                      radius: 10,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        c.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ] else
                    const Spacer(),
                  const SizedBox(width: 8),
                  Text(
                    fmtDateAt(c.date, c.createdAt),
                    style: TextStyle(color: palette.muted, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
