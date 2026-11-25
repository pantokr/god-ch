import '../../../core/widgets/anonymous_author.dart';
import '../../../core/widgets/casual_card.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/toggle_chip.dart';
import '../../people/view/person_avatar.dart';

import 'package:flutter/material.dart';

import '../../people/view/person_popup.dart';

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
import '../../../data/models/tab_access.dart';
import '../../../data/models/member.dart';
import '../../../data/models/prayer.dart';
import '../../../data/models/prayer_settings.dart';
import '../../../data/models/reaction.dart';
import '../../home/view/content_widgets.dart';
import '../../home/view/feature_gate.dart';
import '../../home/view_model/affiliation_choice.dart';
import '../view_model/prayer_list_view_model.dart';
import 'floating_prayers.dart';
import 'postit_card.dart' show kPostItEnabled;
import 'prayer_write_fab.dart';

/// 중보기도: 고른 소속(속한 소속이 없으면 교회 전체)의 공개 중보기도.
/// - 알록달록: 화면 가득 포스트잇 카드가 떠다닌다 (배경은 바깥 틀이 깐다).
/// - 심플: 카드 격자. 카드마다 제목과 내용 미리보기가 있고 아래에 조회수와 응원 수가 보인다.
/// 어느 쪽이든 누르면 중보기도 상세가 열린다. 기도 요청 버튼은 오른쪽 아래에 떠 있다.
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
              // 소속이 바뀌거나 새로고침하면 중보기도를 새로 구독한다.
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

/// 정렬 기준 (개인 설정에서도 고른다).
enum PrayerSort {
  latest('최신순'),
  oldest('오래된순'),
  views('조회순'),
  likes('좋아요순');

  const PrayerSort(this.label);

  final String label;
}

/// 심플 목록. 위에 일정 · 말씀묵상과 같은 검색 · 정렬 순서가 있고, 카드는 말씀묵상 카드와 같은 모양이다.
class PrayerSimpleList extends StatefulWidget {
  const PrayerSimpleList({
    super.key,
    required this.prayers,
    required this.me,
    this.header,
    this.emptyText = '중보기도 없음',
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
  // 개인 설정의 기본 정렬 · 보기로 시작한다.
  late PrayerSort _sort = PrayerSort.values.firstWhere(
    (s) => s.name == AppScope.read(context).preferences.sortOf('prayer'),
    orElse: () => PrayerSort.latest,
  );

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

  /// 검색어(제목 · 이름 · 내용)에 맞는 글을 정렬 기준대로 돌려준다. 읽어 온 순서는 최신순이다.
  List<Prayer> _apply(List<Prayer> all) {
    final list = [
      for (final p in all)
        if (_query.isEmpty ||
            p.title.toLowerCase().contains(_query) ||
            (!p.hidesAuthorFrom(widget.me.id, staff: widget.me.isStaff) &&
                p.authorName.toLowerCase().contains(_query)) ||
            p.content.toLowerCase().contains(_query))
          p,
    ];
    // 읽은 글(내가 쓴 글 포함)을 뺀다. 내 활동 화면에서는 이 조건이 없다.
    if (_hideRead && widget.header == null) {
      list.removeWhere((p) => p.readByUser(widget.me.id));
    }
    switch (_sort) {
      case PrayerSort.latest:
        break;
      case PrayerSort.oldest:
        return list.reversed.toList();
      case PrayerSort.views:
        return list..sort((a, b) => b.views.compareTo(a.views));
      case PrayerSort.likes:
        return list
          ..sort((a, b) => (_likes[b.id] ?? 0).compareTo(_likes[a.id] ?? 0));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: SingleChildScrollView(
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
                      hintText: '중보기도 제목을 입력하세요',
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
                const SizedBox(height: PageTitle.searchGap),
              ],
              if (widget.header == null)
                PageTitle(
                  gap: 32,
                  title: '',
                  description: '서로를 위한 중보기도를 올려 보세요. 함께 중보기도하며 응원을 나눠 보세요.',
                ),
              // 패널 영역과 목록 영역을 가르는 선, 그 아래 목록 윗부분 오른쪽에 새로고침 (말씀묵상과 같다).
              Divider(height: 1, color: context.palette.border),
              // 읽음 제외는 정렬 줄 위에 둔다.
              BleedBox(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 정렬 순서는 패널 밖, 목록 바로 위에 붙고 오른쪽에 새로고침 (일정과 같다).
                    SortStrip(
                      leading: kHideReadEnabled && widget.header == null
                          ? ToggleChip(
                              label: '읽음 제외',
                              on: _hideRead,
                              onTap: () =>
                                  setState(() => _hideRead = !_hideRead),
                            )
                          : null,

                      options: [
                        for (final o in PrayerSort.values)
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
                          if (_sort == PrayerSort.likes) {
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
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
      ),
    );
  }
}

/// 중보기도 카드 하나 (캐주얼): 내용은 싣지 않고, 글쓴이(사진 · 이름) · 날짜 · 소속과 응원 · 댓글 · 조회수만 보인다.
/// 비공개 글은 자물쇠, 안 읽은 새 글은 오른쪽 위에 NEW 알약이 붙는다. 격자에서는 반 너비 카드로 쌓는다.
class PrayerTile extends StatelessWidget {
  const PrayerTile({
    super.key,
    required this.prayer,
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
  final PrayerSettings settings;
  final Prayer prayer;
  final Member me;

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
    final p = prayer;
    // 앱 개발자는 교인이 아니라 읽음 표시가 없다.
    final read =
        !me.isOperatorView &&
        (p.readByUser(me.id) ||
            AppScope.read(context).preferences
                .seen('p/${me.churchId}/${p.id}'));
    // 7일 안에 올라온 안 읽은 글만 "신규". 내가 쓴 글은 표시가 필요 없다 (한 번 열어 읽으면 사라진다).
    final fresh =
        !me.isOperatorView && !read && ReadStatusBar.isFresh(p.createdAt);
    final showBar =
        showFresh && kReadBarEnabled && p.authorId != me.id && fresh;
    final hidden = p.hidesAuthorFrom(me.id, staff: me.isStaff);
    final showAuthor = settings.showAuthor;
    return CasualCard(
      hueSeed: p.id,
      grid: grid,
      gutter: gutter,
      fresh: showBar,
      // 개인 설정: 중보기도 카드 색.
      fill: AppScope.read(context).preferences
          .tintOf('prayer')
          .colorFor(Theme.of(context).brightness),
      onTap: () => context.push(Routes.prayer(me.churchId, p.id), extra: p),
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
              uid: p.authorId,
              name: p.authorName,
              photoUrl: '',
              child: PersonAvatar(
                churchId: me.churchId,
                uid: p.authorId,
                name: p.authorName.isEmpty ? '?' : p.authorName,
                radius: d / 2,
              ),
            ),
      // 글쓴이 이름은 사진 영역에, 제목은 오른쪽에. 제목 없이 쓴 옛 글은 "중보기도"로 둔다.
      // 반 너비 카드와 폰 리스트는 좁아서 줄을 늘려 30자가 다 보이게 한다 (카드가 그만큼 길어진다).
      name: showAuthor ? p.authorLabel(me.id, staff: me.isStaff) : '',
      title: Text(
        p.title.isEmpty ? '중보기도' : p.title,
        maxLines: grid ? 5 : 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: grid ? 14 : 15,
          fontWeight: FontWeight.w400,
          height: 1.35,
        ),
      ),
      // 말씀묵상 카드와 같은 표기(개인 설정의 일시 표기) · 같은 자리(아래 왼쪽).
      date: fmtPosted(p.createdAt),
      stats: _Stats(
        prayer: p,
        me: me,
        showViews: alwaysStats || settings.showViews,
        showAll: alwaysStats,
      ),
    );
  }
}

/// 모든 이모티콘 반응을 합친 반응 수(하트)와 조회수. 응원 수는 저장소에서 실시간으로 읽는다.
/// 내가 반응을 남겼다면 하트가 채워진다.
class _Stats extends StatelessWidget {
  const _Stats({
    required this.prayer,
    required this.me,
    this.showViews = true,
    this.showAll = false,
  });

  /// 비공개 글이어도 댓글 수(0)를 보인다.
  final bool showAll;

  final Prayer prayer;
  final Member me;
  final bool showViews;

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.read(context).prayers;
    return StreamBuilder<ReactionSummary>(
      stream: repo.reactions(me.churchId, prayer.id),
      builder: (context, snap) {
        final r = snap.data ?? ReactionSummary.empty;
        Widget stats(int? comments) => StatIcons(
          locked: !prayer.isPublic,
          horizontal: true,
          showViews: showViews,
          views: prayer.views,
          likes: r.total,
          liked: r.mine.isNotEmpty,
          comments: comments,
        );
        // 댓글은 공개 글에만 달린다.
        if (!prayer.isPublic) return stats(showAll ? 0 : null);
        return StreamBuilder<int>(
          stream: repo.commentCount(me.churchId, prayer.id),
          builder: (context, c) => stats(c.data ?? 0),
        );
      },
    );
  }
}
