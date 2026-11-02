import '../../../core/widgets/app_loader.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/widgets/toggle_chip.dart';
import '../../people/view/person_avatar.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/list_style_controller.dart';
import '../../../app/routes.dart';
import '../../../core/format.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/icons.dart';
import '../../../core/widgets/refresh_scope.dart';
import '../../../core/widgets/read_status_bar.dart';
import '../../../core/widgets/sort_pad.dart';
import '../../../core/widgets/stat_icons.dart';
import '../../../core/theme.dart';
import '../../../data/models/affiliation.dart';
import '../../../data/models/church_features.dart';
import '../../../data/models/member.dart';
import '../../../data/models/prayer.dart';
import '../../../data/models/prayer_settings.dart';
import '../../../data/models/reaction.dart';
import '../../home/view/content_widgets.dart';
import '../../home/view/feature_gate.dart';
import '../../home/view_model/affiliation_choice.dart';
import '../view_model/prayer_list_view_model.dart';
import '../../home/view/affiliation_tag.dart';
import 'floating_prayers.dart';
import 'postit_card.dart' show kPostItEnabled;
import 'prayer_write_fab.dart';

/// 기도제목: 고른 소속(속한 소속이 없으면 교회 전체)의 공개 기도제목.
/// - 알록달록: 화면 가득 포스트잇 카드가 떠다닌다 (배경은 바깥 틀이 깐다).
/// - 심플: 카드 격자. 카드마다 제목과 내용 미리보기가 있고 아래에 조회수와 응원 수가 보인다.
/// 어느 쪽이든 누르면 기도제목 상세가 열린다. 기도 요청 버튼은 오른쪽 아래에 떠 있다.
class PrayerBoardPage extends StatelessWidget {
  const PrayerBoardPage({super.key, required this.me, required this.choice});

  final Member me;
  final AffiliationChoice choice;

  /// 한꺼번에 떠다니는 카드 수.
  static const floating = 4;

  @override
  Widget build(BuildContext context) {
    final style = AppScope.read(context).listStyle;
    return FeatureGate(
      feature: PageFeature.prayer,
      me: me,
      choice: choice,
      builder: (context, affiliation) => RefreshScope(
        builder: (context, generation, refresh) =>
            ViewModelBuilder<PrayerListViewModel>(
              // 소속이 바뀌거나 새로고침하면 기도제목을 새로 구독한다.
              key: ValueKey(
                'board/${me.churchId}/${affiliation?.id}/$generation',
              ),
              create: (context) => PrayerListViewModel(
                AppScope.read(context).prayers
                    .publicFeed(me.churchId, affiliationId: affiliation?.id),
              ),
              builder: (context, vm) => Stack(
                fit: StackFit.expand,
                children: [
                  ListenableBuilder(
                    listenable: style,
                    builder: (context, _) =>
                        kPostItEnabled && style.style == ListStyle.colorful
                        ? FloatingPrayers(
                            prayers: vm.prayers,
                            me: me,
                            count: floating,
                            fullScreen: true,
                          )
                        : PrayerSimpleList(prayers: vm.prayers, me: me),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 16 + MediaQuery.paddingOf(context).bottom,
                    child: PrayerWriteFab(me: me, affiliation: affiliation),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}

/// 정렬 기준.
enum _PrayerSort {
  latest('최신순'),
  oldest('오래된순'),
  views('조회순'),
  likes('좋아요순');

  const _PrayerSort(this.label);

  final String label;
}

/// 심플 목록. 위에 일정 · 말씀묵상과 같은 검색 · 정렬 순서가 있고, 카드는 말씀묵상 카드와 같은 모양이다.
class PrayerSimpleList extends StatefulWidget {
  const PrayerSimpleList({
    super.key,
    required this.prayers,
    required this.me,
    this.header,
    this.emptyText = '기도제목 없음',
  });

  final Stream<List<Prayer>> prayers;
  final Member me;

  /// 내 활동의 제목과 스위치. 있으면 검색 필드는 그 아래에 놓이고 탭 설명은 따로 두지 않는다.
  final Widget? header;
  final String emptyText;

  @override
  State<PrayerSimpleList> createState() => _PrayerSimpleListState();
}

class _PrayerSimpleListState extends State<PrayerSimpleList> {
  final _search = TextEditingController();
  String _query = '';

  /// 이미 읽은 글을 빼고 보는가.
  bool _hideRead = false;
  _PrayerSort _sort = _PrayerSort.latest;

  /// 글별 응원(이모티콘) 합. 좋아요순으로 정렬할 때 처음 한 번 읽어 둔다.
  final Map<String, int> _likes = {};
  bool _loadingLikes = false;

  Future<void> _ensureLikes(List<Prayer> all) async {
    if (_loadingLikes) return;
    final missing = [
      for (final p in all)
        if (!_likes.containsKey(p.id)) p,
    ];
    if (missing.isEmpty) return;
    _loadingLikes = true;
    final repo = AppScope.read(context).prayers;
    final totals = await Future.wait([
      for (final p in missing)
        repo
            .reactions(widget.me.churchId, p.id)
            .first
            .then((r) => r.total, onError: (_) => 0),
    ]);
    _loadingLikes = false;
    if (!mounted) return;
    setState(() {
      for (var i = 0; i < missing.length; i++) {
        _likes[missing[i].id] = totals[i];
      }
    });
  }

  /// 교회가 정한 중보기도 운영 설정 (조회수 · 글쓴이 공개). 한 번만 구독한다.
  late final Stream<PrayerSettings> _settings = AppScope.read(context).prayers
      .settings(widget.me.churchId);

  /// 글의 소속 이름을 알기 위한 소속 목록 (한 번만 구독한다).
  late final Stream<List<Affiliation>> _affiliations = AppScope.read(context)
      .affiliations
      .affiliations(widget.me.churchId);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// 검색어(이름 · 내용)에 맞는 글을 정렬 기준대로 돌려준다. 읽어 온 순서는 최신순이다.
  List<Prayer> _apply(List<Prayer> all) {
    final list = [
      for (final p in all)
        if (_query.isEmpty ||
            p.authorName.toLowerCase().contains(_query) ||
            p.content.toLowerCase().contains(_query))
          p,
    ];
    // 읽은 글(내가 쓴 글 포함)을 뺀다. 내 활동 화면에서는 이 조건이 없다.
    if (_hideRead && widget.header == null) {
      list.removeWhere((p) => p.readByUser(widget.me.id));
    }
    switch (_sort) {
      case _PrayerSort.latest:
        break;
      case _PrayerSort.oldest:
        return list.reversed.toList();
      case _PrayerSort.views:
        return list..sort((a, b) => b.views.compareTo(a.views));
      case _PrayerSort.likes:
        return list
          ..sort((a, b) => (_likes[b.id] ?? 0).compareTo(_likes[a.id] ?? 0));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // 오른쪽 아래의 기도 요청 버튼에 마지막 줄이 가리지 않게 아래를 비운다.
      padding: const EdgeInsets.only(bottom: 88),
      child: PageFrame(
        header: widget.header,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 검색 필드는 탭 설명 위에 있다 (내 활동에는 없다).
            if (widget.header == null) ...[
              PadSearchField(
                child: TextField(
                  controller: _search,
                  onChanged: (v) =>
                      setState(() => _query = v.trim().toLowerCase()),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: '기도제목을 입력하세요',
                    isDense: true,
                    suffixIcon: _query.isEmpty
                        ? const Icon(AppIcons.magnifyingGlass, size: 18)
                        : IconButton(
                            icon: const Icon(AppIcons.x, size: 18),
                            onPressed: () {
                              _search.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (widget.header == null)
              PageTitle(
                gap: 32,
                title: '',
                description: '교인이 서로를 위해 올리는 기도제목입니다. 함께 기도하며 응원을 나눕니다.',
              ),
            // 패널 영역과 목록 영역을 가르는 선, 그 아래 목록 윗부분 오른쪽에 새로고침 (말씀묵상과 같다).
            Divider(height: 1, color: context.palette.border),
            // 읽음 제외는 정렬 줄 위에 둔다.
            BleedBox(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.header == null)
                    Padding(
                      padding: EdgeInsets.only(
                        top: 12,
                        right: textGutter(context),
                      ),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: ToggleChip(
                          label: '읽음 제외',
                          on: _hideRead,
                          onTap: () => setState(() => _hideRead = !_hideRead),
                        ),
                      ),
                    ),
                  // 정렬 순서는 패널 밖, 목록 바로 위에 붙고 오른쪽에 새로고침 (일정과 같다).
                  SortStrip(
                    options: [
                      for (final o in _PrayerSort.values)
                        PadOption(
                          o.label,
                          selected: _sort == o,
                          onTap: () => setState(() => _sort = o),
                        ),
                    ],
                  ),
                  SortBody(
                    child: StreamBuilder<List<Prayer>>(
                      stream: widget.prayers,
                      builder: (context, snap) {
                        if (snap.hasError) {
                          return EmptyHint('불러오지 못했습니다\n${snap.error}');
                        }
                        final all = snap.data;
                        if (all == null) {
                          return const Padding(
                            padding: EdgeInsets.all(48),
                            child: Center(child: AppLoader()),
                          );
                        }
                        if (_sort == _PrayerSort.likes) {
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => _ensureLikes(all),
                          );
                        }
                        final items = _apply(all);
                        if (items.isEmpty) {
                          return EmptyHint(
                            all.isEmpty ? widget.emptyText : '검색 결과 없음',
                          );
                        }
                        return StreamBuilder<List<Affiliation>>(
                          stream: _affiliations,
                          builder: (context, affs) {
                            final names = {
                              for (final a
                                  in affs.data ?? const <Affiliation>[])
                                a.id: a.name,
                            };
                            return StreamBuilder<PrayerSettings>(
                              stream: _settings,
                              initialData: PrayerSettings.standard,
                              builder: (context, set) => Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (final p in items)
                                    PrayerTile(
                                      prayer: p,
                                      me: widget.me,
                                      affiliationNames: names,
                                      settings:
                                          set.data ?? PrayerSettings.standard,
                                    ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 기도제목 카드 하나 (말씀묵상 카드와 같은 모양): 각진 테두리, 맨 위에 읽은 글은 회색 "읽음" 바, 안 읽은 글은 붉은 "신규" 바.
/// 비공개 글은 자물쇠. 위에서 아래로: 하트와 응원 수(오른쪽) → 내용 발췌(두 줄) → 글쓴이(왼쪽)와 날짜·시각(맞은편).
class PrayerTile extends StatelessWidget {
  const PrayerTile({
    super.key,
    required this.prayer,
    required this.me,
    required this.settings,
    this.affiliationNames = const {},
  });

  final PrayerSettings settings;
  final Prayer prayer;
  final Member me;

  /// 소속 아이디 → 이름. 글의 소속을 이름 옆에 보여줄 때 쓴다.
  final Map<String, String> affiliationNames;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final p = prayer;
    // 앱 개발자는 교인이 아니라 읽음 표시가 없다.
    final read = !me.isOperatorView && p.readByUser(me.id);
    // 읽은 글은 "읽음", 7일 안에 올라온 안 읽은 글은 "신규", 오래된 안 읽은 글은 바가 없다.
    final fresh =
        !me.isOperatorView && !read && ReadStatusBar.isFresh(p.createdAt);
    // 내가 쓴 글은 읽음 · 신규 표시가 필요 없다.
    final showBar = kReadBarEnabled && p.authorId != me.id && (read || fresh);
    // 글이 짧든 길든 카드 높이가 같도록 글 영역은 늘 정해진 줄 수만큼 자리를 잡는다.
    final scaler = MediaQuery.textScalerOf(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        textGutter(context),
        0,
        textGutter(context),
        14,
      ),
      child: InkWell(
        onTap: () => context.push(Routes.prayer(me.churchId, p.id), extra: p),
        borderRadius: BorderRadius.circular(4),
        child: Ink(
          // 읽음 · 신규 바는 카드 맨 위 가장자리에 붙으므로 위쪽 여백은 바 아래에서 시작한다.
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            color: palette.surface,
            border: Border.all(color: context.cardEdge),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 바가 있든 없든 카드 맨 위 높이는 같다 (모든 카드가 같은 높이).
              if (showBar) ...[
                read
                    ? ReadStatusBar.read(color: palette.muted)
                    : const ReadStatusBar.fresh(),
                const SizedBox(height: 14),
              ] else
                SizedBox(
                  height: kReadBarEnabled ? ReadStatusBar.height + 14 : 16,
                ),
              // 비공개 글의 자물쇠는 내용 앞에 붙는다 (말씀묵상의 제목 앞과 같다).
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!p.isPublic) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Icon(
                        AppIcons.lock,
                        size: 14,
                        color: palette.muted,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  // 내용은 앞부분만 발췌해 두 줄 자리를 늘 잡는다.
                  Expanded(
                    child: SizedBox(
                      height: scaler.scale(14 * 1.45 * 2),
                      child: Text(
                        p.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, height: 1.45),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 하트(응원 수)와 조회수는 오른쪽에, 이 글의 소속은 그 맞은편 왼쪽에 둔다.
              SizedBox(
                height: 24,
                child: Row(
                  children: [
                    if (affiliationLabel(affiliationNames, p.affiliationId)
                        case final name?)
                      AffiliationTag(name),
                    // 반응 · 조회수는 오른쪽 끝에 붙는다.
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _Stats(
                          prayer: p,
                          me: me,
                          showViews: settings.showViews,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (settings.showAuthor) ...[
                    PersonAvatar(
                      churchId: me.churchId,
                      uid: p.authorId,
                      name: p.authorName.isEmpty ? '?' : p.authorName,
                      radius: 10,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        p.authorName.isEmpty ? '이름 없음' : p.authorName,
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
                    fmtDateTime(p.createdAt),
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

/// 이모티콘별 응원 수(받은 종류를 전부)와 조회수. 응원 수는 저장소에서 실시간으로 읽는다.
/// 내가 누른 이모티콘은 진하게 보인다. 좁은 자리에서는 줄어들어 한 줄에 맞춘다.
class _Stats extends StatelessWidget {
  const _Stats({required this.prayer, required this.me, this.showViews = true});

  final Prayer prayer;
  final Member me;
  final bool showViews;

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.read(context).prayers;
    final palette = context.palette;
    return StreamBuilder<ReactionSummary>(
      stream: repo.reactions(me.churchId, prayer.id),
      builder: (context, snap) {
        final r = snap.data ?? ReactionSummary.empty;
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final t in reactionTypes)
                if ((r.counts[t.id] ?? 0) > 0) ...[
                  Text(
                    t.emoji,
                    style: TextStyle(
                      fontSize: 14,
                      color: r.mine.contains(t.id) ? null : palette.muted,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    StatIcons.compact(r.counts[t.id]!),
                    style: TextStyle(
                      color: r.mine.contains(t.id)
                          ? palette.ink
                          : palette.muted,
                      fontSize: 12.5,
                      fontWeight: r.mine.contains(t.id)
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              if (showViews) ...[
                Icon(AppIcons.eyeCount, size: 16, color: palette.muted),
                const SizedBox(width: 4),
                Text(
                  StatIcons.compact(prayer.views),
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
