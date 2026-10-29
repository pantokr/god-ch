import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/list_style_controller.dart';
import '../../../app/routes.dart';
import '../../../core/icons.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/stat_icons.dart';
import '../../../data/models/meeting.dart';
import '../../../data/models/member.dart';
import '../../home/view/content_widgets.dart';
import '../view_model/meetings_view_model.dart';
import 'meeting_format.dart';
import 'meeting_form.dart';

/// 모임 목록. 알록달록은 색이 있는 카드 격자, 심플은 글 중심 목록이다 ([ListStyleController]).
/// 카드에는 남은 자리 · 제목 · 모임장 · 날짜와 장소가 있고, 누르면 상세가 열린다.
/// 교인은 누구나 모임을 만들 수 있다 (만든 사람이 모임장).
class MeetingsPage extends StatelessWidget {
  const MeetingsPage({super.key, required this.me});

  final Member me;

  @override
  Widget build(BuildContext context) {
    final style = AppScope.read(context).listStyle;
    return ViewModelBuilder<MeetingsViewModel>(
      key: ValueKey('meetings/${me.churchId}'),
      create: (context) => MeetingsViewModel(
        AppScope.read(context).meetings,
        me.churchId,
        me.name,
      ),
      builder: (context, vm) => SingleChildScrollView(
        child: PageFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageTitle(
                title: '모임',
                // 앱 개발자는 교인이 아니므로 모임을 만들 수 없다.
                action: me.isOperatorView
                    ? null
                    : FilledButton.icon(
                        onPressed: vm.busy ? null : () => _create(context, vm),
                        icon: const Icon(AppIcons.plus, size: 18),
                        label: const Text('만들기'),
                      ),
              ),
              StreamBuilder<List<Meeting>>(
                stream: vm.items,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return EmptyHint('불러오지 못했습니다\n${snap.error}');
                  }
                  final items = snap.data;
                  if (items == null) {
                    return const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (items.isEmpty) return const EmptyHint('모임 없음');
                  return ListenableBuilder(
                    listenable: style,
                    builder: (context, _) => style.style == ListStyle.colorful
                        ? ColumnWrap(
                            wide: 3,
                            narrow: 2,
                            children: [
                              for (final m in items)
                                _ColorfulCard(meeting: m, me: me),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0; i < items.length; i++)
                                _MinimalRow(
                                  meeting: items[i],
                                  me: me,
                                  last: i == items.length - 1,
                                ),
                            ],
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context, MeetingsViewModel vm) async {
    final result = await showMeetingForm(context);
    if (result == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (!await vm.create(result) && vm.error != null) {
      messenger.showSnackBar(SnackBar(content: Text(vm.error!)));
    }
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
  const _ColorfulCard({required this.meeting, required this.me});

  final Meeting meeting;
  final Member me;

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
          color: Pastel.fill(context, Pastel.indexOf(m.id)),
          border: Border.all(color: hue.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1.3,
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
                  Positioned(left: 8, top: 8, child: _SeatBadge(meeting: m)),
                  Positioned(
                    right: 10,
                    top: 8,
                    child: Row(
                      children: [
                        Icon(
                          liked ? AppIcons.heartFill : AppIcons.heart,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${m.likes}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: palette.muted, fontSize: 12.5),
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
                        '${seatLabel(m)} · ${m.joined}/${m.capacity}명',
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
