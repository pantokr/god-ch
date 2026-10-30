import '../../../core/widgets/toast.dart';
import '../../../core/widgets/app_loader.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/list_style_controller.dart';
import '../../../app/routes.dart';
import '../../../core/icons.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/widgets/toggle_chip.dart';
import '../../../core/widgets/like_heart.dart';
import '../../../core/widgets/create_fab.dart';
import '../../../core/widgets/refresh_scope.dart';
import '../../../core/widgets/sort_pad.dart';
import '../../../core/widgets/thumbnail_avatar.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/stat_icons.dart';
import '../../../data/models/permission.dart';
import '../../../data/models/meeting.dart';
import '../../../data/models/member.dart';
import '../../home/view/content_widgets.dart';
import '../view_model/meetings_view_model.dart';
import 'meeting_format.dart';
import 'meeting_form.dart';

/// 모임 목록. 기본(알록달록)은 2열 카드 격자, 심플은 글 중심 목록이다 ([ListStyleController]).
/// 카드에는 남은 자리 · 제목 · 모임장 · 날짜와 장소가 있고, 누르면 상세가 열린다.
/// 모임은 교역자 이상이 만든다 (만든 사람이 모임장).
class MeetingsPage extends StatelessWidget {
  const MeetingsPage({super.key, required this.me});

  final Member me;

  @override
  Widget build(BuildContext context) {
    return RefreshScope(
      builder: (context, generation, refresh) =>
          ViewModelBuilder<MeetingsViewModel>(
            key: ValueKey('meetings/${me.churchId}/$generation'),
            create: (context) => MeetingsViewModel(
              AppScope.read(context).meetings,
              me.churchId,
              me.name,
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
                          title: '모임',
                          description: '교회 안의 모임을 한눈에 봅니다. 마음에 드는 모임에 참여를 신청하고, 하트로 모아 둘 수 있어요. 정원이 찼거나 지난 모임은 마감으로 표시됩니다.',
                        ),
                        _SortPanel(vm: vm),
                        const SizedBox(height: 16),
                        // 패널 영역과 목록 영역을 가르는 선, 그 아래 목록 윗부분 오른쪽에 새로고침.
                        Divider(height: 1, color: context.palette.border),
                        // 마감 제외는 일정에만 있어서 새로고침의 반대편(왼쪽)에 둔다.
                        Row(
                          children: [
                            // 눌러서 켜고 끄는 조건: 테두리 알약에 체크 표시.
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: ToggleChip(
                                label: '마감 제외',
                                on: vm.hideClosed,
                                onTap: vm.toggleHideClosed,
                              ),
                            ),
                            const Spacer(),
                            refresh,
                          ],
                        ),
                        StreamBuilder<List<Meeting>>(
                          stream: vm.items,
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
                            final items = vm.apply(all);
                            if (items.isEmpty) {
                              return EmptyHint(
                                all.isEmpty ? '모임 없음' : '해당 모임 없음',
                              );
                            }
                            return MeetingListView(
                              meetings: items,
                              me: me,
                              onLike: me.isOperatorView
                                  ? null
                                  : (m, liked) =>
                                        vm.setLike(m.id, liked: liked),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                // 모임은 교역자 이상이 만든다. 앱 개발자는 교인이 아니라 만들지 않는다.
                if (me.can(Permission.meetingCreate) && !me.isOperatorView)
                  Positioned(
                    right: 16,
                    bottom: 16 + MediaQuery.paddingOf(context).bottom,
                    child: CreateFab(
                      label: '모임 만들기',
                      onTap: vm.busy ? null : () => _create(context, vm),
                    ),
                  ),
              ],
            ),
          ),
    );
  }

  Future<void> _create(BuildContext context, MeetingsViewModel vm) async {
    final result = await showMeetingForm(context, upload: vm.uploadImage);
    if (result == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final inset = MediaQuery.paddingOf(context).bottom;
    if (await vm.create(result)) {
      showToastOn(messenger, '추가되었습니다', bottom: inset);
    } else if (vm.error != null) {
      messenger.showSnackBar(SnackBar(content: Text(vm.error!)));
    }
  }
}

/// 모임 목록 본체: 알록달록은 2열 카드 격자, 심플은 글 중심 줄이다 ([ListStyleController]).
/// 일정 탭과 내 활동의 일정이 같은 모양으로 쓴다. [onLike]가 없으면 하트를 눌러도 반응하지 않는다.
class MeetingListView extends StatelessWidget {
  const MeetingListView({
    super.key,
    required this.meetings,
    required this.me,
    this.onLike,
  });

  final List<Meeting> meetings;
  final Member me;
  final void Function(Meeting meeting, bool liked)? onLike;

  @override
  Widget build(BuildContext context) {
    final style = AppScope.read(context).listStyle;
    return ListenableBuilder(
      listenable: style,
      builder: (context, _) => style.style == ListStyle.colorful
          ? _CardGrid(
              children: [
                for (final m in meetings)
                  _ColorfulCard(
                    meeting: m,
                    me: me,
                    onLike: onLike == null
                        ? null
                        : (liked) => onLike!(m, liked),
                  ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < meetings.length; i++)
                  _MinimalRow(
                    meeting: meetings[i],
                    me: me,
                    last: i == meetings.length - 1,
                  ),
              ],
            ),
    );
  }
}

/// 검색 · 정렬 영역.
class _SortPanel extends StatefulWidget {
  const _SortPanel({required this.vm});

  final MeetingsViewModel vm;

  @override
  State<_SortPanel> createState() => _SortPanelState();
}

class _SortPanelState extends State<_SortPanel> {
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
      // 말씀묵상 · 중보기도와 같은 검색창 (제목 · 장소 · 모임장 · 소개).
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
        PadGroup(label: '정렬 순서', [
          for (final s in MeetingSort.values)
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

/// 2열 격자. 모든 카드가 같은 크기다 (이미지 높이는 폭에 맞추고, 글 영역은 고정 높이).
class _CardGrid extends StatelessWidget {
  const _CardGrid({required this.children});

  final List<Widget> children;

  static const gap = 12.0;

  /// 글 영역 높이: 제목 2줄 + 모임장 + 날짜·장소.
  static const textHeight = 132.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final width = (box.maxWidth - gap) / 2;
        final scale = MediaQuery.textScalerOf(context).scale(1);
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: gap,
          crossAxisSpacing: gap,
          childAspectRatio:
              width / (width / _ColorfulCard.imageRatio + textHeight * scale),
          children: children,
        );
      },
    );
  }
}

/// 남은 자리 표시: 빨간 배지. 지난 모임은 회색 "종료", 정원이 찬 모임은 "마감".
String seatLabel(Meeting m) => m.ended
    ? '종료'
    : m.isFull
    ? '마감'
    : '${m.seatsLeft}자리 남음';

/// 알록달록: 색이 있는 윗부분에 남은 자리 배지와 하트, 아래에 제목 · 모임장 · 날짜와 장소.
class _ColorfulCard extends StatelessWidget {
  const _ColorfulCard({required this.meeting, required this.me, this.onLike});

  final Meeting meeting;
  final Member me;

  /// 하트를 눌렀을 때 (누른 뒤의 상태). 앱 개발자는 교인이 아니라 null이다.
  final void Function(bool liked)? onLike;

  /// 이미지 영역의 가로:세로 비.
  static const imageRatio = meetingThumbRatio;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final m = meeting;
    final hue = Pastel.hue(Pastel.indexOf(m.id));
    final liked = m.likedByUser(me.id);
    return InkWell(
      onTap: () => context.push(Routes.meeting(me.churchId, m.id)),
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Ink(
        decoration: BoxDecoration(
          color: palette.surface,
          border: Border.all(color: palette.border),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: _ColorfulCard.imageRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          hue.withValues(alpha: 0.85),
                          hue.withValues(alpha: 0.45),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppRadius.card),
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        AppIcons.usersThree,
                        size: 44,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.card),
                    ),
                    child: MeetingThumb(m),
                  ),
                  // 남은 자리 배지 오른쪽에 D-N을 따로 둔다.
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _SeatBadge(meeting: m),
                        if (meetingDDay(m.date) case final d?) ...[
                          const SizedBox(width: 4),
                          _DDayBadge(label: d),
                        ],
                      ],
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    // 버튼처럼 보이지 않게: 배경 · 툴팁 · 눌림 효과 없이 하트만 이미지 위에 둔다 (눌러서 바꾸는 것은 그대로).
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onLike == null ? null : () => onLike!(!liked),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: LikeHeart(
                          liked: liked,
                          size: 22,
                          likedColor: const Color(0xFFFF6B7A),
                          unlikedColor: Colors.white,
                          shadows: const [
                            Shadow(blurRadius: 6, color: Color(0x73000000)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목은 한 줄이어도 두 줄 높이를 잡아 카드 모양을 맞춘다.
                    SizedBox(
                      height:
                          15 *
                          1.3 *
                          2 *
                          MediaQuery.textScalerOf(context).scale(1),
                      child: Text(
                        m.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          foregroundDecoration: avatarRing(context, 9),
                          child: CircleAvatar(
                            radius: 9,
                            backgroundColor: hue,
                            child: Text(
                              m.leaderName.isEmpty
                                  ? '?'
                                  : m.leaderName.characters.first,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            m.leaderName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      meetingLine(m.date, m.place),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: palette.muted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 남은 날 배지: 남은 자리 배지 오른쪽에 놓는 짙은 면의 작은 글씨.
class _DDayBadge extends StatelessWidget {
  const _DDayBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SeatBadge extends StatelessWidget {
  const _SeatBadge({required this.meeting});

  final Meeting meeting;

  @override
  Widget build(BuildContext context) {
    final gray = meeting.ended || meeting.isFull;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: gray ? const Color(0xFF6B6B7B) : const Color(0xFFD7261E),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          seatLabel(meeting),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

/// 심플: 구분선만 있는 글 중심 줄. 오른쪽 가장자리에 조회수 · 좋아요와 참여 인원.
class _MinimalRow extends StatelessWidget {
  const _MinimalRow({
    required this.meeting,
    required this.me,
    required this.last,
  });

  final Meeting meeting;
  final Member me;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final m = meeting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => context.push(Routes.meeting(me.churchId, m.id)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.control),
                    child: MeetingThumb(m),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${m.leaderName} · ${meetingLine(m.date, m.place)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: palette.muted, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${seatLabel(m)}${meetingDDay(m.date) == null ? '' : ' · ${meetingDDay(m.date)}'} · ${m.joined}/${m.capacity}명',
                        style: TextStyle(
                          color: m.ended || m.isFull
                              ? palette.muted
                              : const Color(0xFFD7261E),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                StatIcons(
                  views: m.views,
                  likes: m.likes,
                  liked: m.likedByUser(me.id),
                ),
              ],
            ),
          ),
        ),
        if (!last) Divider(height: 1, color: palette.border),
      ],
    );
  }
}
