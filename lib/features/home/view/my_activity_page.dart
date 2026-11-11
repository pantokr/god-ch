import '../../../data/bible_reference.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/format.dart';
import '../../../core/icons.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/shadow_switch.dart';
import '../../../core/widgets/stat_icons.dart' show Pastel;
import '../../../core/widgets/sort_pad.dart';
import '../../../core/widgets/view_mode_toggle.dart';
import '../../../data/models/affiliation.dart';
import '../../../data/models/church_content.dart';
import '../../../data/models/devotion_settings.dart';
import '../../../data/models/meeting.dart';
import '../../../data/models/member.dart';
import '../../../data/models/my_comment.dart';
import '../../../data/models/prayer.dart';
import '../../../data/models/permission.dart';
import '../../../data/models/prayer_settings.dart';
import '../../bible/view/bible_page.dart' show DevotionCard;
import '../../meetings/view/meeting_format.dart';
import '../../meetings/view/meetings_page.dart'
    show DDayBadge, MeetingInfoLine, SeatBadge;
import '../../meetings/view_model/my_meetings_view_model.dart';
import '../../prayers/view/prayer_board_page.dart' show PrayerTile;
import '../view_model/my_posts_view_model.dart';
import 'content_widgets.dart';

/// "내 활동": 위에는 내가 참여 신청한 일정이 좌우로 밀리는 카드로 있고(자세히 보기에서 참여 예정 · 관심 · 완료 일정),
/// 아래에는 내가 쓴 중보기도와 말씀묵상을 한 목록으로 모아 종류별로 거른다.
class MyActivityPage extends StatelessWidget {
  const MyActivityPage({super.key, required this.me});

  final Member me;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: PageFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 두 영역은 각자 흰 박스이고, 그 사이의 좁은 틈만 바탕색이다.
            BleedBox(child: _MySchedule(me: me)),
            const SizedBox(height: 8),
            BleedBox(
              padding: const EdgeInsets.only(top: 20),
              child: _MyPosts(me: me),
            ),
          ],
        ),
      ),
    );
  }
}

/// 참여 신청한 일정을 좌우로 미는 카드로 보여 주는 영역. 오른쪽 위 "자세히 보기"로 일정 모음 페이지가 열린다.
class _MySchedule extends StatelessWidget {
  const _MySchedule({required this.me});

  final Member me;

  static const _cardWidth = 232.0;

  /// 카드 높이: 썸네일 · 여백은 고정이고, 글 영역은 글씨 배율에 따라 커진다 (고정이면 글씨가 커질 때 넘친다).
  static double heightOf(BuildContext context) =>
      108 + 22 + 92 * MediaQuery.textScalerOf(context).scale(1);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ViewModelBuilder<MyMeetingsViewModel>(
      create: (context) => MyMeetingsViewModel(
        AppScope.read(context).meetings,
        me.churchId,
        me.id,
      ),
      builder: (context, vm) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Gutter(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '참여 신청한 일정',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(
                    Routes.section(me.churchId, ChurchSection.myMeetings),
                  ),
                  style: TextButton.styleFrom(foregroundColor: palette.ink),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('내 일정 관리'),
                      SizedBox(width: 2),
                      Icon(AppIcons.caretRight, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<Meeting>>(
            stream: vm.items,
            builder: (context, snap) {
              if (snap.hasError) {
                return const EmptyHint('불러오지 못했습니다');
              }
              if (!snap.hasData) {
                return SizedBox(
                  height: heightOf(context),
                  child: Center(child: AppLoader()),
                );
              }
              // 기본 보기가 참여 예정이라, 참여 신청했거나 이끄는 앞으로의 모임이 나온다.
              final items = vm.apply(snap.data!);
              if (items.isEmpty) return const EmptyHint('참여 신청한 일정 없음');
              return SizedBox(
                height: heightOf(context),
                child: ListView.separated(
                  // 미는 목록은 화면 끝까지 밀리고, 시작과 끝만 안쪽 여백을 둔다.
                  padding: EdgeInsets.symmetric(
                    horizontal: textGutter(context),
                  ),
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, i) =>
                      _SlideCard(meeting: items[i], me: me, width: _cardWidth),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 좌우로 미는 일정 카드 한 장: 썸네일, 제목, 날짜 · 장소, 남은 날.
class _SlideCard extends StatelessWidget {
  const _SlideCard({
    required this.meeting,
    required this.me,
    required this.width,
  });

  final Meeting meeting;
  final Member me;
  final double width;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final m = meeting;
    final dday = meetingDDay(m.date);
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: () => context.push(Routes.meeting(me.churchId, m.id)),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          decoration: BoxDecoration(
            color: palette.surface,
            border: Border.all(color: context.cardEdge),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 썸네일 안쪽 왼쪽 위에 남은 자리와 D-N 배지.
              SizedBox(
                height: 108,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppRadius.card),
                      ),
                      child: MeetingThumb(m),
                    ),
                    Positioned(
                      left: 6,
                      top: 6,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SeatBadge(meeting: m),
                          if (dday != null) ...[
                            const SizedBox(width: 4),
                            DDayBadge(label: dday),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    MeetingInfoLine(
                      AppIcons.calendarDays,
                      meetingDayTime(m.date),
                    ),
                    if (m.place.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      MeetingInfoLine(AppIcons.mapPin, m.place),
                    ],
                    const SizedBox(height: 2),
                    MeetingInfoLine(AppIcons.wallet, meetingFee(m)),
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

/// 내가 쓴 것 모음: 종류 스위치(중보기도 · 말씀묵상 · 내 댓글) → 정렬 줄 → 목록.
class _MyPosts extends StatefulWidget {
  const _MyPosts({required this.me});

  final Member me;

  @override
  State<_MyPosts> createState() => _MyPostsState();
}

class _MyPostsState extends State<_MyPosts> {
  // 글 카드가 쓰는 운영 설정과 소속 이름: 한 번만 구독한다.
  late final _prayerSettings = AppScope.read(context).prayers
      .settings(widget.me.churchId);
  late final _devotionSettings = AppScope.read(context).contents
      .settings(widget.me.churchId);
  late final _affiliations = AppScope.read(context).affiliations
      .affiliations(widget.me.churchId);

  /// 격자형(2열)으로 보는가. 아니면 리스트형이다 (중보기도 · 말씀묵상 목록과 같다).
  late bool _grid = AppScope.read(context).preferences.gridOf('mine');

  @override
  Widget build(BuildContext context) {
    final me = widget.me;
    return ViewModelBuilder<MyPostsViewModel>(
      create: (context) {
        final scope = AppScope.read(context);
        return MyPostsViewModel(
          scope.prayers,
          scope.contents,
          scope.reflections,
          me.churchId,
          me.id,
          includePrivate: me.canAll(Permission.devotionPrivate),
          affiliationIds: me.isStaff ? null : me.affiliationIds,
        )..initDefaults(sort: scope.preferences.sortOf('mine'));
      },
      builder: (context, vm) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ShadowSwitch<MyPostFilter>(
              values: MyPostFilter.values,
              selected: vm.filter,
              onChanged: vm.setFilter,
              labelOf: (f) => f.label,
            ),
          ),
          const SizedBox(height: 16),
          SortStrip(
            // 댓글은 카드 목록이 아니라 리스트형만 있다.
            viewToggle: vm.filter == MyPostFilter.comment
                ? null
                : ViewModeToggle(
                    grid: _grid,
                    onChanged: (g) => setState(() => _grid = g),
                  ),
            options: [
              for (final s in vm.sortOptions)
                PadOption(
                  s.label,
                  selected: vm.sort == s,
                  onTap: () => vm.setSort(s),
                ),
            ],
          ),
          SortBody(
            child: switch (vm.filter) {
              MyPostFilter.prayer => _Loaded<Prayer>(
                data: vm.prayerList,
                error: vm.prayerError,
                empty: '쓴 중보기도 없음',
                builder: (list) {
                  if (vm.sort == MyPostSort.likes) {
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => vm.ensureLikes(list),
                    );
                  }
                  return _CardList(
                    prayerSettings: _prayerSettings,
                    devotionSettings: _devotionSettings,
                    affiliations: _affiliations,
                    grid: _grid,
                    cards: (names, prayerSet, devotionSet) => [
                      for (final p in vm.sortedPrayers(list))
                        PrayerTile(
                          prayer: p,
                          me: me,
                          affiliationNames: names,
                          settings: prayerSet,
                          gutter: _grid ? 0 : null,
                          grid: _grid,
                          alwaysStats: true,
                          showFresh: false,
                        ),
                    ],
                  );
                },
              ),
              MyPostFilter.devotion => _Loaded<ChurchContent>(
                data: vm.devotionList,
                error: vm.devotionError,
                empty: '쓴 말씀묵상 없음',
                builder: (list) => _CardList(
                  prayerSettings: _prayerSettings,
                  devotionSettings: _devotionSettings,
                  affiliations: _affiliations,
                  grid: _grid,
                  cards: (names, prayerSet, devotionSet) => [
                    for (final c in vm.sortedDevotions(list))
                      DevotionCard(
                        content: c,
                        me: me,
                        affiliationNames: names,
                        settings: devotionSet,
                        gutter: _grid ? 0 : null,
                        grid: _grid,
                        alwaysStats: true,
                        showFresh: false,
                      ),
                  ],
                ),
              ),
              MyPostFilter.comment => _Loaded<MyComment>(
                data: vm.commentList,
                error: vm.commentError,
                empty: '남긴 댓글 없음',
                builder: (list) => _CommentList(
                  comments: vm.sortedComments(list),
                  churchId: me.churchId,
                ),
              ),
            },
          ),
        ],
      ),
    );
  }
}

/// 불러오는 중 · 오류 · 빈 목록을 처리하고, 값이 있으면 [builder]로 그린다.
class _Loaded<T> extends StatelessWidget {
  const _Loaded({
    required this.data,
    required this.error,
    required this.empty,
    required this.builder,
  });

  final List<T>? data;
  final Object? error;
  final String empty;
  final Widget Function(List<T> list) builder;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return EmptyHint('불러오지 못했습니다${String.fromCharCode(10)}$error');
    }
    if (data == null) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: AppLoader()),
      );
    }
    if (data!.isEmpty) return EmptyHint(empty);
    return builder(data!);
  }
}

/// 중보기도 · 말씀묵상 카드들: 설정과 소속 이름을 받아 [cards]가 카드를 만든다.
class _CardList extends StatelessWidget {
  const _CardList({
    required this.prayerSettings,
    required this.devotionSettings,
    required this.affiliations,
    required this.cards,
    required this.grid,
  });

  /// 격자형이면 카드를 2열로 놓는다.
  final bool grid;
  final Stream<PrayerSettings> prayerSettings;
  final Stream<DevotionSettings> devotionSettings;
  final Stream<List<Affiliation>> affiliations;
  final List<Widget> Function(
    Map<String, String> names,
    PrayerSettings prayerSet,
    DevotionSettings devotionSet,
  )
  cards;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PrayerSettings>(
      stream: prayerSettings,
      initialData: PrayerSettings.standard,
      builder: (context, prayerSet) => StreamBuilder<DevotionSettings>(
        stream: devotionSettings,
        initialData: DevotionSettings.standard,
        builder: (context, devotionSet) => StreamBuilder<List<Affiliation>>(
          stream: affiliations,
          builder: (context, affs) {
            final names = {
              for (final a in affs.data ?? const <Affiliation>[]) a.id: a.name,
            };
            final children = cards(
              names,
              prayerSet.data ?? PrayerSettings.standard,
              devotionSet.data ?? DevotionSettings.standard,
            );
            if (grid) return TwoColumn(children: children);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            );
          },
        ),
      ),
    );
  }
}

/// 내 댓글 목록: 중보기도 · 말씀묵상 카드와 같은 각진 테두리 카드. 카드마다 어디에 단 댓글인지(종류 · 글 제목), 날짜, 내 댓글이 있고
/// 누르면 그 댓글이 달린 일정 · 중보기도 · 말씀묵상이 열린다.
class _CommentList extends StatelessWidget {
  const _CommentList({required this.comments, required this.churchId});

  final List<MyComment> comments;
  final String churchId;

  void _open(BuildContext context, MyComment c) {
    final path = switch (c.target) {
      CommentTarget.meeting => Routes.meeting(churchId, c.targetId),
      CommentTarget.prayer => Routes.prayer(churchId, c.targetId),
      CommentTarget.devotion => Routes.devotion(churchId, c.targetId),
    };
    context.push(path);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final gutter = textGutter(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final c in comments)
          Padding(
            padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 14),
            child: InkWell(
              onTap: () => _open(context, c),
              borderRadius: BorderRadius.circular(4),
              child: Ink(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: palette.surface,
                  border: Border.all(color: context.cardEdge),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 어디에 단 댓글인지: 분류(유채색)와 글 제목(무채색)은 각각의 말풍선에 (왼쪽), 날짜는 오른쪽 끝.
                    Row(
                      children: [
                        _Bubble(
                          color: Pastel.hue(c.target.index)
                              .withValues(alpha: 0.28),
                          child: Text(
                            c.target.label,
                            style: TextStyle(
                              color: palette.ink,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                        if (c.targetTitle.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: c.target == CommentTarget.prayer
                                  // 중보기도: 그 사람을 향해 보냈다는 표시로, 이름 앞에 보냄 아이콘이 붙는다.
                                  ? _Bubble(
                                      color: palette.accent.withValues(
                                        alpha: 0.18,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            AppIcons.paperPlaneRight,
                                            size: 13,
                                            color: palette.accent,
                                          ),
                                          const SizedBox(width: 5),
                                          Flexible(
                                            child: Text(
                                              c.targetTitle,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: palette.ink,
                                                fontSize: 12.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : _Bubble(
                                      color: palette.ink.withValues(
                                        alpha: 0.06,
                                      ),
                                      child: Text(
                                        normalizeVerseTitle(c.targetTitle),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: palette.muted,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ] else
                          const Spacer(),
                        const SizedBox(width: 8),
                        Text(
                          fmtDateTime(c.date),
                          style: TextStyle(
                            color: palette.muted,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      c.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 말풍선 하나: 둥근 모서리의 색 바탕 위에 짧은 글.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: child,
      ),
    );
  }
}
