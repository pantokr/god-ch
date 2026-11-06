import '../../../core/widgets/app_loader.dart';

import 'package:flutter/material.dart';

import '../../../data/models/person_card.dart';
import '../../people/view/person_avatar.dart';
import '../../people/view/person_popup.dart';

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
import '../../../data/models/permission.dart';
import '../../../data/models/meeting.dart';
import '../../../data/models/member.dart';
import '../view_model/meeting_detail_view_model.dart';
import 'meeting_comments_card.dart';
import 'meeting_form.dart';
import 'meeting_format.dart';
import '../../../core/format.dart';
import '../../home/view/post_meta.dart';
import 'meetings_page.dart' show seatStatus;

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
                // 사진 · 제목 · 소개 → 일시 · 장소 정보 → 참여 → 모임장(좋아요 · 조회수 포함) → 댓글.
                _InfoCard(meeting: m, churchId: me.churchId),
                const SizedBox(height: 12),
                _InfoCard(meeting: m, churchId: me.churchId, details: true),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _JoinCard(meeting: m, me: me, vm: vm),
                  ),
                ),
                const SizedBox(height: 12),
                _LeaderCard(meeting: m, churchId: me.churchId, me: me, vm: vm),
                const SizedBox(height: 12),
                MeetingCommentsCard(
                  meetingId: m.id,
                  me: me,
                  canWrite: vm.settings.allowComments,
                  publicList: vm.settings.commentsPublic,
                ),
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
      me: me,
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.meeting,
    required this.churchId,
    this.details = false,
  });

  final Meeting meeting;
  final String churchId;

  /// true이면 일시 · 장소 · 회비 · 입장 조건 카드, 아니면 사진 · 제목 · 모임장 카드.
  final bool details;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final m = meeting;
    Widget row(IconData icon, String label, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: palette.muted),
          const SizedBox(width: 10),
          SizedBox(
            width: 72,
            child: Text(label, style: TextStyle(color: palette.muted)),
          ),
          Expanded(child: Text(text)),
        ],
      ),
    );
    if (details) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              row(AppIcons.calendarDays, '일시', meetingWhen(m.date)),
              if (m.place.isNotEmpty) row(AppIcons.mapPin, '장소', m.place),
              row(AppIcons.wallet, '회비', meetingFee(m)),
              row(
                AppIcons.userCheck,
                '입장 조건',
                m.needsApproval ? '모임장 승인' : '자유 참여',
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 사진이 없어도 목록처럼 기본 이미지 칸을 보여준다.
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.control),
              child: AspectRatio(aspectRatio: 1.3, child: MeetingThumb(m)),
            ),
            const SizedBox(height: 16),
            Text(m.title, style: Theme.of(context).textTheme.titleLarge),
            if (m.description.isNotEmpty) ...[
              const SizedBox(height: 28),
              SelectableText(
                m.description,
                style: const TextStyle(height: 1.6),
              ),
            ],
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
    final pending = m.pendingBy(me.id);
    final isLeader = m.leaderId == me.id;
    final Widget button;
    if (me.isOperatorView) {
      button = const SizedBox.shrink();
    } else if (!me.can(Permission.meetingJoin)) {
      button = const OutlinedButton(onPressed: null, child: Text('참여 권한 없음'));
    } else if (joined) {
      button = OutlinedButton(
        // 이미 지난(종료된) 모임은 참여를 취소할 수 없다.
        onPressed: vm.busy || m.ended ? null : () => vm.setJoined(m, false),
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
        ),
        child: const Text('참여 취소'),
      );
    } else if (pending) {
      // 모임장 승인 대기 중: 신청을 취소할 수 있다.
      button = OutlinedButton(
        onPressed: vm.busy || m.ended ? null : () => vm.setJoined(m, false),
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
        ),
        child: const Text('신청 취소'),
      );
    } else if (!m.openTo(
      isStaff: me.isStaff,
      affiliationIds: me.affiliationIds,
    )) {
      // 공개 범위(소속) 밖의 교인은 참여할 수 없다.
      button = const OutlinedButton(onPressed: null, child: Text('소속 전용'));
    } else {
      button = FilledButton(
        onPressed: vm.busy || m.isFull || m.ended
            ? null
            : () => vm.setJoined(m, true, applicantName: me.name),
        child: Text(
          m.ended
              ? '종료'
              : m.isFull
              ? '마감'
              : '참여 신청',
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(AppIcons.usersThree, size: 18, color: context.palette.accent),
            const SizedBox(width: 8),
            Text(
              ['참여 ${m.joined}/${m.capacity}명', ?seatStatus(m)].join(' · '),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            if (!me.isOperatorView)
              _StatusBubble(
                label: joined
                    ? (m.ended ? '참여 완료' : '참여 예정')
                    : pending
                    ? '승인 대기'
                    : '미참여',
                active: joined || pending,
              ),
          ],
        ),
        const SizedBox(height: 12),
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
        // 모임장과 승인 권한이 있는 사람(교회 관리자 포함)에게만: 승인을 기다리는 신청자 목록.
        if ((isLeader || me.can(Permission.meetingApprove)) &&
            m.pendingIds.isNotEmpty) ...[
          const SizedBox(height: 20),
          _PendingRequests(meeting: m, me: me, vm: vm),
        ],
        // 모임장 · 교회 운영자에게만: 참여자 목록 페이지로 가는 줄.
        if ((isLeader ||
                me.isOperatorView ||
                me.can(Permission.meetingViewParticipants)) &&
            m.participantIds.isNotEmpty) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () =>
                context.push(Routes.meetingParticipants(me.churchId, m.id)),
            icon: const Icon(AppIcons.usersThree, size: 18),
            label: Text('참여자 ${m.participantIds.length}명'),
          ),
        ],
      ],
    );
  }
}

/// 내 참여 상태를 보여주는 작은 말풍선 (미참여 · 승인 대기 · 참여 예정 · 참여 완료).
class _StatusBubble extends StatelessWidget {
  const _StatusBubble({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? palette.accent.withValues(alpha: 0.12) : null,
        border: active ? null : Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? palette.accent : palette.muted,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// 모임장 정보 카드: 프로필 · 이름과 등록일이 한 줄에 나란히, 그 아래 조회수, 맨 아래 좋아요
/// (중보기도 · 말씀묵상 상세의 작성 정보 카드와 같은 모양).
class _LeaderCard extends StatelessWidget {
  const _LeaderCard({
    required this.meeting,
    required this.churchId,
    required this.me,
    required this.vm,
  });

  final Meeting meeting;
  final String churchId;
  final Member me;
  final MeetingDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    final m = meeting;
    final liked = m.likedByUser(me.id);
    return PostInfoCard(
      meta: PostMeta(
        churchId: churchId,
        author: PostAuthor(
          avatar: PersonTap(
            churchId: churchId,
            uid: m.leaderId,
            name: m.leaderName,
            child: PersonAvatar(
              churchId: churchId,
              uid: m.leaderId,
              name: m.leaderName.isEmpty ? '?' : m.leaderName,
              radius: PostAuthor.avatarRadius,
            ),
          ),
          name: PersonTap(
            churchId: churchId,
            uid: m.leaderId,
            name: m.leaderName,
            child: Text(
              m.leaderName.isEmpty ? '이름 없음' : m.leaderName,
              style: PostAuthor.nameStyle(context),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        date: fmtDateTime(m.createdAt),
        views: vm.settings.showViews ? m.views : null,
        isPrivate: false,
        // 공개 여부(공개 · 교역자 전용)는 없고, 공개 범위(소속)만 보인다.
        showPrivacy: false,
        affiliationId: m.affiliationId,
      ),
      footer: vm.settings.allowLikes
          ? LikeButton(
              liked: liked,
              count: m.likes,
              showCount: vm.settings.showLikeCount,
              onTap: me.isOperatorView ? null : () => vm.setLike(!liked),
            )
          : null,
    );
  }
}

/// 상세에서 바로 처리할 수 있게 보여 주는 승인 대기 인원 (나머지는 참여자 페이지에서 처리한다).
const _pendingPreview = 3;

/// 승인을 기다리는 참여 신청자 목록(모임장 전용): 이름과 승인 · 거절 버튼.
class _PendingRequests extends StatelessWidget {
  const _PendingRequests({
    required this.meeting,
    required this.me,
    required this.vm,
  });

  final Meeting meeting;
  final Member me;
  final MeetingDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    final m = meeting;
    final palette = context.palette;
    return StreamBuilder<List<PersonCard>>(
      stream: AppScope.read(context).people.people(me.churchId),
      builder: (context, snap) {
        final names = {
          for (final p in snap.data ?? const <PersonCard>[]) p.id: p.name,
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '승인 대기 ${m.pendingIds.length}명',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            // 대기자가 많아져도 화면이 끝없이 늘어나지 않게 앞의 몇 명만 보인다.
            for (final uid in m.pendingIds.take(_pendingPreview))
              SizedBox(
                height: 52,
                child: Row(
                  children: [
                    PersonTap(
                      churchId: me.churchId,
                      uid: uid,
                      name: names[uid] ?? '',
                      child: PersonAvatar(
                        churchId: me.churchId,
                        uid: uid,
                        name: names[uid] ?? '?',
                        radius: 14,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        names[uid] ?? '이름 없음',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: vm.busy ? null : () => vm.reject(m, uid),
                      style: TextButton.styleFrom(
                        foregroundColor: palette.muted,
                      ),
                      child: const Text('거절'),
                    ),
                    FilledButton(
                      // 정원이 찼으면 승인할 수 없다.
                      onPressed: vm.busy || m.isFull
                          ? null
                          : () => vm.approve(m, uid),
                      child: const Text('승인'),
                    ),
                  ],
                ),
              ),
            if (m.pendingIds.length > _pendingPreview)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => context.push(
                    Routes.meetingParticipants(me.churchId, m.id),
                  ),
                  child: Text(
                    '더보기 (+${m.pendingIds.length - _pendingPreview})',
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
