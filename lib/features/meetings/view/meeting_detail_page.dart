import '../../../core/widgets/app_loader.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/widgets/like_button.dart';
import '../../../core/widgets/trash_icon.dart';
import '../../../core/icons.dart';
import '../../../core/layout/confirm_dialog.dart';
import '../../../core/layout/sub_page.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/stat_icons.dart';
import '../../../data/models/permission.dart';
import '../../../data/models/meeting.dart';
import '../../../data/models/member.dart';
import '../view_model/meeting_detail_view_model.dart';
import 'meeting_comments_card.dart';
import 'meeting_form.dart';
import '../../home/view/content_widgets.dart';
import 'meeting_format.dart';
import 'meetings_page.dart' show seatLabel;

/// 주소 `/churches/:cid/meeting/:id`: 모임 상세. 정보 · 소개 · 참여 · 반응이 분리된 카드로 보인다.
/// 모임장과 교역자는 고치고 지울 수 있고, 다른 교인은 참여를 신청하거나 취소한다.
class MeetingDetailPage extends StatelessWidget {
  const MeetingDetailPage({super.key, required this.me, required this.id});

  final Member me;
  final String id;

  @override
  Widget build(BuildContext context) {
    final back = Routes.section(me.churchId, ChurchSection.meetings);
    return ViewModelBuilder<MeetingDetailViewModel>(
      key: ValueKey('meeting/$id'),
      create: (context) => MeetingDetailViewModel(
        AppScope.read(context).meetings,
        me.churchId,
        id,
      ),
      builder: (context, vm) => StreamBuilder<Meeting?>(
        stream: vm.meeting,
        builder: (context, snap) {
          final m = snap.data;
          if (m == null) {
            return SubPage(
              title: '모임',
              fallbackLocation: back,
              child: snap.connectionState == ConnectionState.waiting
                  ? const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: AppLoader()),
                    )
                  : const Card(
                      child: Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(child: Text('볼 수 없는 모임입니다.')),
                      ),
                    ),
            );
          }
          final canManage =
              m.leaderId == me.id || me.can(Permission.meetingDelete);
          return SubPage(
            title: m.title,
            fallbackLocation: back,
            actions: [
              if (canManage) ...[
                TextButton.icon(
                  icon: const Icon(AppIcons.pencilSimple, size: 18),
                  label: const Text('수정'),
                  onPressed: () => _edit(context, vm, m),
                ),
                TextButton.icon(
                  style: TrashIcon.textStyle(context),
                  icon: const TrashIcon(),
                  label: const Text('삭제'),
                  onPressed: () => _delete(context, vm, m, back),
                ),
              ],
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InfoCard(meeting: m),
                const SizedBox(height: 12),
                // 좋아요 · 조회수는 말씀묵상과 같은 반응 카드로 첫 카드 바로 아래에 둔다.
                _ReactionCard(meeting: m, me: me, vm: vm),
                if (m.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _Section(
                    icon: AppIcons.sparkles,
                    label: '소개',
                    child: SelectableText(
                      m.description,
                      style: const TextStyle(height: 1.6),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _JoinCard(meeting: m, me: me, vm: vm),
                const SizedBox(height: 12),
                MeetingCommentsCard(meetingId: m.id, me: me),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    MeetingDetailViewModel vm,
    Meeting m,
  ) async {
    final result = await showMeetingForm(
      context,
      initial: m,
      upload: vm.uploadImage,
    );
    if (result == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (!await vm.update(m, result) && vm.error != null) {
      messenger.showSnackBar(SnackBar(content: Text(vm.error!)));
    }
  }

  Future<void> _delete(
    BuildContext context,
    MeetingDetailViewModel vm,
    Meeting m,
    String back,
  ) async {
    final router = GoRouter.of(context);
    final ok = await confirmChange(
      context,
      title: '모임 삭제',
      body: '"${m.title}"을(를) 삭제할까요?',
      confirmLabel: '삭제',
      danger: true,
    );
    if (!ok) return;
    if (await vm.delete()) {
      router.canPop() ? router.pop() : router.go(back);
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: palette.accent),
                const SizedBox(width: 8),
                Text(label, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.meeting});

  final Meeting meeting;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final m = meeting;
    Widget row(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: palette.muted),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (m.imageUrl.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.control),
                child: AspectRatio(
                  aspectRatio: 1.3,
                  child: ContentImage(m.imageUrl),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(m.title, style: Theme.of(context).textTheme.titleLarge),
            row(AppIcons.user, '모임장 ${m.leaderName}'),
            row(AppIcons.calendarDays, meetingWhen(m.date)),
            if (m.place.isNotEmpty) row(AppIcons.mapPin, m.place),
          ],
        ),
      ),
    );
  }
}

/// 참여: 인원 막대와 신청 · 취소 버튼.
class _JoinCard extends StatelessWidget {
  const _JoinCard({required this.meeting, required this.me, required this.vm});

  final Meeting meeting;
  final Member me;
  final MeetingDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    final m = meeting;
    final joined = m.joinedBy(me.id);
    final isLeader = m.leaderId == me.id;
    final Widget button;
    if (me.isOperatorView) {
      button = const SizedBox.shrink();
    } else if (isLeader) {
      button = const OutlinedButton(onPressed: null, child: Text('내가 모임장'));
    } else if (!me.can(Permission.meetingJoin)) {
      button = const OutlinedButton(onPressed: null, child: Text('참여 권한 없음'));
    } else if (joined) {
      button = OutlinedButton(
        // 이미 지난(종료된) 모임은 참여를 취소할 수 없다.
        onPressed: vm.busy || m.ended ? null : () => vm.setJoined(false),
        child: const Text('참여 취소'),
      );
    } else {
      button = FilledButton(
        onPressed: vm.busy || m.isFull || m.ended
            ? null
            : () => vm.setJoined(true),
        child: Text(
          m.ended
              ? '종료'
              : m.isFull
              ? '마감'
              : '참여 신청',
        ),
      );
    }
    return _Section(
      icon: AppIcons.usersThree,
      label: '참여 ${m.joined}/${m.capacity}명 · ${seatLabel(m)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: m.capacity == 0 ? 0 : m.joined / m.capacity,
              minHeight: 8,
            ),
          ),
          if (vm.error != null) ...[
            const SizedBox(height: 8),
            Text(
              vm.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 14),
          button,
        ],
      ),
    );
  }
}

/// 반응: 좋아요 버튼과 조회수. 말씀묵상 상세의 반응 카드와 같은 모양이다.
class _ReactionCard extends StatelessWidget {
  const _ReactionCard({
    required this.meeting,
    required this.me,
    required this.vm,
  });

  final Meeting meeting;
  final Member me;
  final MeetingDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    final liked = meeting.likedByUser(me.id);
    final muted = context.palette.muted;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(
          children: [
            LikeButton(
              liked: liked,
              count: meeting.likes,
              onTap: me.isOperatorView ? null : () => vm.setLike(!liked),
            ),
            const Spacer(),
            Icon(AppIcons.eyeCount, size: 16, color: muted),
            const SizedBox(width: 4),
            Text(
              '조회 ${StatIcons.compact(meeting.views)}',
              style: TextStyle(color: muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
