import '../../../core/widgets/anonymous_author.dart';
import '../../../core/widgets/casual_card.dart';
import '../../../data/bible_reference.dart' show splitVerseTitle;
import '../../../core/widgets/toast.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/widgets/toggle_chip.dart';
import '../../../core/widgets/app_loader.dart';

import 'package:flutter/material.dart';

import '../../people/view/person_popup.dart';

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
import '../../../core/widgets/read_status_bar.dart';
import '../../../core/widgets/sort_pad.dart';
import '../../../core/widgets/stat_icons.dart';
import '../../../core/widgets/thumbnail_avatar.dart';
import '../../../data/models/permission.dart';
import '../../../data/models/affiliation.dart';
import '../../../data/models/church_content.dart';
import '../../../data/models/tab_access.dart';
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
      builder: (context, affiliation) => RefreshScope(
        builder: (context, generation, refresh) => ViewModelBuilder<DevotionsViewModel>(
          key: ValueKey('bible/${me.churchId}/$generation'),
          create: (context) =>
              DevotionsViewModel(
                AppScope.read(context).contents,
                me.churchId,
                authorName: me.name,
                authorPhotoUrl: me.photoUrl,
                affiliations: AppScope.read(context).affiliations
                    .affiliations(me.churchId),
                includePrivate: me.canAll(Permission.devotionPrivate),
                // 교역자 이상이 아니면 자기가 속한 소속의 글만 읽는다 (미배정이면 아무것도 없다).
                affiliationIds: me.isStaff ? null : me.affiliationIds,
                readerId: me.id,
                readerIsStaff: me.isStaff,
              )..initDefaults(
                grid: false,
                sort: AppScope.read(context).preferences.sortOf('bible'),
              ),
          builder: (context, vm) => Stack(
            fit: StackFit.expand,
            children: [
              SelectionArea(
                child: SingleChildScrollView(
                  // 오른쪽 아래 버튼에 마지막 줄이 가리지 않게 아래를 비운다.
                  padding: const EdgeInsets.only(bottom: CreateFab.clearance),
                  child: PageFrame(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 검색 필드는 탭 설명 위에 있다.
                        _SearchField(vm: vm),
                        const SizedBox(height: PageTitle.searchGap),
                        PageTitle(
                          gap: 32,
                          title: '',
                          description:
                              '오늘의 말씀 구절을 읽어 보세요. 묵상을 읽고 나의 묵상도 남겨 보세요.',
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
                                  final items = vm.apply(
                                    all,
                                    affiliationId: affiliation?.id,
                                  );
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // 최근 글쓴이는 구분선 위에 있다.
                                      _RecentAuthors(
                                        visible: vm.settings.showAuthor,
                                        viewerId: me.id,
                                        staff: me.isStaff,
                                        authors:
                                            DevotionsViewModel.recentAuthors(
                                              all,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      // 위 영역과 목록 영역을 가르는 선.
                                      Divider(
                                        height: 1,
                                        color: context.palette.border,
                                      ),
                                      // 읽음 제외는 정렬 줄 위에 둔다.
                                      BleedBox(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            // 정렬 순서는 패널 밖, 목록 바로 위에 붙는다 (일정과 같다).
                                            SortStrip(
                                              leading: kHideReadEnabled
                                                  ? ToggleChip(
                                                      label: '읽음 제외',
                                                      on: vm.hideRead,
                                                      onTap: vm.toggleHideRead,
                                                    )
                                                  : null,

                                              options: [
                                                for (final s
                                                    in DevotionSort.values)
                                                  PadOption(
                                                    s.label,
                                                    selected: vm.sort == s,
                                                    onTap: () => vm.setSort(s),
                                                  ),
                                              ],
                                            ),
                                            SortBody(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  if (items.isEmpty)
                                                    EmptyHint(
                                                      all.isEmpty
                                                          ? '말씀 없음'
                                                          : '검색 결과 없음',
                                                    )
                                                  else
                                                    for (final c in items)
                                                      DevotionCard(
                                                        content: c,
                                                        me: me,
                                                        settings: vm.settings,
                                                        affiliationNames: {
                                                          for (final a
                                                              in affiliations ??
                                                                  const <
                                                                    Affiliation
                                                                  >[])
                                                            a.id: a.name,
                                                        },
                                                      ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
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
              ),
              if (me.can(Permission.devotionPost))
                Positioned(
                  right: 16,
                  bottom: 16 + MediaQuery.paddingOf(context).bottom,
                  child: CreateFab(
                    label: '말씀묵상 작성',
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
      extras: result.extras,
      date: result.date,
      affiliationId: result.affiliationId,
      isPrivate: result.isPrivate,
      authorHidden: result.authorHidden,
    );
    if (ok) {
      showToastOn(messenger, '추가되었습니다', bottom: inset);
    } else if (vm.error != null) {
      showToastOn(messenger, vm.error!);
    }
  }
}

/// 최근 글을 쓴 사람들: "7일간 [프로필 사진들] 의 사람들이 묵상했습니다" 한 줄.
/// 사진은 작게 겹쳐 놓고 5명을 넘으면 "+N"으로 줄인다.
class _RecentAuthors extends StatelessWidget {
  const _RecentAuthors({
    required this.authors,
    required this.viewerId,
    required this.staff,
    this.visible = true,
  });

  /// 글쓴이가 가려진 글(작성자 비공개)을 사진 대신 익명으로 보이기 위한 보는 사람.
  final String viewerId;
  final bool staff;

  /// 최근 7일 안에 글을 쓴 사람들 (최신 글 순서, 중복 없음).
  final List<ChurchContent> authors;

  /// 글쓴이 공개 설정이 꺼져 있으면 숨긴다.
  final bool visible;

  /// 프로필 사진으로 보이는 최대 인원. 넘으면 나머지는 "+N"으로 줄인다.
  static const maxShown = 5;

  static const _radius = 13.0;
  static const _ring = 1.5;
  static const _step = 20.0;

  @override
  Widget build(BuildContext context) {
    if (!visible || authors.isEmpty) return const SizedBox.shrink();
    final palette = context.palette;
    const size = (_radius + _ring) * 2;
    final shown = authors.take(maxShown).toList();
    final more = authors.length - shown.length;
    final count = shown.length + (more > 0 ? 1 : 0);
    final text = TextStyle(color: palette.ink, fontSize: 14);
    Widget ring(Widget child) => DecoratedBox(
      decoration: BoxDecoration(shape: BoxShape.circle, color: palette.surface),
      child: Padding(padding: const EdgeInsets.all(_ring), child: child),
    );
    // 유채색 띠는 화면(페이지 영역) 좌우 끝까지 퍼지고, 내용은 카드와 같은 여백 안에 놓인다.
    final extra = PageBleed.maybeOf(context)?.extra ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -extra,
            right: -extra,
            top: 0,
            bottom: 0,
            child: ColoredBox(color: Pastel.hue(2).withValues(alpha: 0.22)),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: textGutter(context),
              vertical: 8,
            ),
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
                            message:
                                shown[i].hidesAuthorFrom(viewerId, staff: staff)
                                ? anonymousName
                                : shown[i].authorName,
                            child: ring(
                              shown[i].hidesAuthorFrom(viewerId, staff: staff)
                                  ? const AnonymousAvatar(radius: _radius)
                                  : ThumbnailAvatar(
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
                                backgroundColor: Pastel.hue(2)
                                    .withValues(alpha: 0.35),
                                child: Text(
                                  '+$more',
                                  style: TextStyle(
                                    color: palette.ink,
                                    fontSize: 11,
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
          ),
        ],
      ),
    );
  }
}

/// 말씀묵상 카드 하나 (캐주얼): 본문 · 묵상은 싣지 않고 권 · 장 · 절만 크게 보인다.
/// 책 이름이 제목이고 아래에 "3장 16절" 알약이 붙는다. 글쓴이 · 날짜는 아래 왼쪽, 좋아요 · 댓글 · 조회수는 오른쪽이다.
class DevotionCard extends StatelessWidget {
  const DevotionCard({
    super.key,
    required this.content,
    required this.me,
    required this.settings,
    this.affiliationNames = const {},
    this.gutter,
    this.grid = false,
    this.alwaysStats = false,
    this.showFresh = true,
  });

  /// 신규 표시를 붙이는가 (내 활동에서는 끈다).
  final bool showFresh;

  /// 설정과 상관없이 댓글 · 반응 · 조회수를 0이어도 모두 보인다 (내 활동).
  final bool alwaysStats;
  final ChurchContent content;
  final Member me;
  final DevotionSettings settings;

  /// 소속 아이디 → 이름. 글의 소속을 보여줄 때 쓴다.
  final Map<String, String> affiliationNames;

  /// 카드 좌우 바깥 여백. 없으면 글 여백(`textGutter`)이고, 격자에서는 0이다.
  final double? gutter;

  /// 격자형 카드인가: 반 너비라서 위 아래로 쌓는다.
  final bool grid;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    // 글을 열면(개인 설정에 기록) 신규 표시가 바로 사라지도록, 설정이 바뀔 때 다시 그린다.
    listenable: AppScope.read(context).preferences,
    builder: (context, _) => _card(context),
  );

  Widget _card(BuildContext context) {
    final palette = context.palette;
    final c = content;
    // 앱 개발자는 교인이 아니라 읽음 표시가 없다.
    final read =
        !me.isOperatorView &&
        (c.readBy.contains(me.id) ||
            AppScope.read(context).preferences
                .seen('d/${me.churchId}/${c.id}'));
    // 7일 안에 올라온 안 읽은 글만 "신규". 내가 쓴 글은 표시가 필요 없다 (한 번 열어 읽으면 사라진다).
    final fresh =
        !me.isOperatorView && !read && ReadStatusBar.isFresh(c.createdAt);
    final showBar =
        showFresh && kReadBarEnabled && c.authorId != me.id && fresh;
    // 책 이름과 장 · 절. 읽을 수 없는 제목은 통째로 제목에 둔다. 말씀이 여러 벌이면 "외 N".
    final split = splitVerseTitle(c.title);
    // 말씀이 여러 벌이면 구절 아래 줄에 작게 "외 N".
    final more = c.extras.isEmpty ? '' : '외 ${c.extras.length}';
    final showAuthor = c.authorName.isNotEmpty && settings.showAuthor;
    final hidden = c.hidesAuthorFrom(me.id, staff: me.isStaff);
    final hasComments =
        alwaysStats || settings.allowReflections || settings.reflectionsPublic;
    Widget stats({int? comments}) => StatIcons(
      locked: c.isPrivate,
      horizontal: true,
      showViews: alwaysStats || settings.showViews,
      showLikeCount: alwaysStats || settings.showLikeCount,
      views: c.views,
      likes: c.likes,
      liked: c.likedBy.contains(me.id),
      comments: comments,
    );
    return CasualCard(
      hueSeed: c.id,
      grid: grid,
      gutter: gutter,
      fresh: showBar,
      // 개인 설정: 말씀묵상 카드 색.
      fill: AppScope.read(context).preferences
          .tintOf('bible')
          .colorFor(Theme.of(context).brightness),
      onTap: () => context.push(Routes.devotion(me.churchId, c.id)),
      // 글쓴이의 사진. 글쓴이를 보이지 않는 교회 설정이면 사람 아이콘이다.
      leading: (d) => !showAuthor
          ? ColoredBox(
              color: palette.brand.withValues(alpha: 0.12),
              child: SizedBox(
                width: d,
                height: d,
                child: Icon(AppIcons.user, color: palette.brand),
              ),
            )
          : hidden
          ? AnonymousAvatar(radius: d / 2)
          : PersonTap(
              churchId: me.churchId,
              uid: c.authorId,
              name: c.authorName,
              photoUrl: c.authorPhotoUrl,
              child: ThumbnailAvatar(
                name: c.authorName,
                url: c.authorPhotoUrl,
                radius: d / 2,
              ),
            ),
      // 글쓴이 이름은 사진 영역에, 구절(창세기 1장 1절)은 오른쪽에. 굵은 글씨는 쓰지 않는다.
      name: showAuthor ? c.authorLabel(me.id, staff: me.isStaff) : '',
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            split == null ? c.title : '${split.$1} ${split.$2}',
            // 중보기도 제목(PrayerTile)과 같은 줄 수 · 크기 · 굵기.
            maxLines: grid ? 5 : 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: grid ? 14 : 15,
              fontWeight: FontWeight.w400,
              height: 1.35,
            ),
          ),
          if (more.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                more,
                style: TextStyle(
                  color: palette.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
        ],
      ),
      // 중보기도 카드와 같은 표기(개인 설정의 일시 표기) · 같은 자리(아래 왼쪽).
      date: fmtPosted(c.createdAt ?? c.date),
      // 댓글 수: 댓글이 꺼져 있거나, 비공개이고 교역자가 아니면 읽을 수 없어 뺀다.
      stats: hasComments
          ? StreamBuilder<int>(
              stream: settings.reflectionsPublic || me.isStaff
                  ? AppScope.read(context).reflections.count(me.churchId, c.id)
                  : Stream<int>.value(0),
              builder: (context, n) => stats(
                comments:
                    alwaysStats || settings.reflectionsPublic || me.isStaff
                    ? (n.data ?? 0)
                    : null,
              ),
            )
          : stats(),
    );
  }
}

/// 말씀묵상 검색 필드: 탭 설명 위에 놓인다.
class _SearchField extends StatefulWidget {
  const _SearchField({required this.vm});

  final DevotionsViewModel vm;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final _search = TextEditingController(text: widget.vm.query);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    return PadSearchField(
      child: TextField(
        controller: _search,
        onChanged: vm.setQuery,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: '말씀묵상 내용을 입력하세요',
          isDense: true,
          suffixIcon: vm.query.isEmpty
              ? const Icon(AppIcons.magnifyingGlass, size: 18)
              : IconButton(
                  icon: const Icon(AppIcons.x, size: 18),
                  onPressed: () {
                    _search.clear();
                    vm.setQuery('');
                  },
                ),
        ),
      ),
    );
  }
}
