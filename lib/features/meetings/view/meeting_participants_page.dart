import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/layout/confirm_dialog.dart';
import '../../../core/layout/sub_page.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_inputs.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/sort_pad.dart';
import '../../../data/models/affiliation.dart';
import '../../../data/models/meeting.dart';
import '../../../data/models/member.dart';
import '../../../data/models/permission.dart';
import '../../../data/models/person_card.dart';
import '../../people/view/person_row.dart';
import '../view_model/meeting_detail_view_model.dart';

enum _ParticipantSort {
  name('이름순'),
  joined('신청순'),
  position('직급순');

  const _ParticipantSort(this.label);

  final String label;
}

/// 주소 `/churches/:cid/meeting/:id/participants`: 모임 참여자 목록(모임장 · 교회 운영자).
/// 이름 · 직급 검색과 정렬, 내보내기가 된다.
class MeetingParticipantsPage extends StatefulWidget {
  const MeetingParticipantsPage({
    super.key,
    required this.me,
    required this.id,
  });

  final Member me;
  final String id;

  @override
  State<MeetingParticipantsPage> createState() =>
      _MeetingParticipantsPageState();
}

class _MeetingParticipantsPageState extends State<MeetingParticipantsPage> {
  String _query = '';
  _ParticipantSort _sort = _ParticipantSort.name;

  Member get me => widget.me;

  // 사람 목록은 한 번만 구독한다.
  late final Stream<List<PersonCard>> _people = AppScope.read(context).people
      .people(me.churchId);

  late final Stream<List<Affiliation>> _affiliations = AppScope.read(context)
      .affiliations
      .affiliations(me.churchId);

  @override
  Widget build(BuildContext context) {
    final back = Routes.meeting(me.churchId, widget.id);
    return ViewModelBuilder<MeetingDetailViewModel>(
      key: ValueKey('meeting-participants/${widget.id}'),
      create: (context) => MeetingDetailViewModel(
        AppScope.read(context).meetings,
        me.churchId,
        widget.id,
      ),
      builder: (context, vm) => StreamBuilder<Meeting?>(
        stream: vm.meeting,
        builder: (context, snap) {
          final m = snap.data;
          // 참여자 목록은 조회 권한이, 승인 대기는 승인 권한(모임장 포함)이 있어야 본다.
          final canView =
              m != null &&
              (m.leaderId == me.id ||
                  me.isOperatorView ||
                  me.canAll(Permission.meetingParticipants));
          final canApprove =
              m != null &&
              (m.leaderId == me.id ||
                  me.isOperatorView ||
                  me.canAll(Permission.meetingParticipants));
          final allowed = canView || canApprove;
          return SubPage(
            title: '참여자',
            fallbackLocation: back,
            child: m == null || !allowed
                ? Padding(
                    padding: const EdgeInsets.all(48),
                    child: Center(
                      child: snap.connectionState == ConnectionState.waiting
                          ? const AppLoader()
                          // 일정이 없거나 볼 수 없는 것과, 일정은 있어도 이 권한이 없는 것을 구별해 알린다.
                          : Text(m == null ? '볼 수 없는 목록입니다.' : '권한이 없습니다'),
                    ),
                  )
                : StreamBuilder<List<Affiliation>>(
                    stream: _affiliations,
                    builder: (context, affs) => StreamBuilder<List<PersonCard>>(
                      stream: _people,
                      builder: (context, people) => _body(
                        context,
                        vm,
                        m,
                        canView: canView,
                        canApprove: canApprove,
                        cards: {
                          for (final p in people.data ?? const <PersonCard>[])
                            p.id: p,
                        },
                        affiliationNames: {
                          for (final a in affs.data ?? const <Affiliation>[])
                            a.id: a.name,
                        },
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _body(
    BuildContext context,
    MeetingDetailViewModel vm,
    Meeting m, {
    required bool canView,
    required bool canApprove,
    required Map<String, PersonCard> cards,
    required Map<String, String> affiliationNames,
  }) {
    final q = _query.toLowerCase();
    // 신청순은 participantIds에 쌓인 순서다.
    final order = {
      for (var i = 0; i < m.participantIds.length; i++) m.participantIds[i]: i,
    };
    String nameOf(String id) => cards[id]?.name ?? '';
    final rows =
        m.participantIds.where((id) {
          if (q.isEmpty) return true;
          return nameOf(id).toLowerCase().contains(q) ||
              (cards[id]?.positionName ?? '').toLowerCase().contains(q);
        }).toList()..sort((a, b) {
          switch (_sort) {
            case _ParticipantSort.name:
              return nameOf(a).compareTo(nameOf(b));
            case _ParticipantSort.joined:
              return order[a]!.compareTo(order[b]!);
            case _ParticipantSort.position:
              final pa = cards[a]?.positionName ?? '';
              final pb = cards[b]?.positionName ?? '';
              if (pa.isEmpty != pb.isEmpty) return pa.isEmpty ? 1 : -1;
              final r = pa.compareTo(pb);
              return r != 0 ? r : nameOf(a).compareTo(nameOf(b));
          }
        });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 승인 대기: 이 페이지에서 모두 처리한다 (일정 화면에는 앞의 몇 명만 보인다).
        if (canApprove && m.pendingIds.isNotEmpty) ...[
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: Text(
                    '승인 대기 (${m.pendingIds.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                for (final id in m.pendingIds) ...[
                  const Divider(height: 1),
                  _PendingRow(
                    me: me,
                    meeting: m,
                    vm: vm,
                    uid: id,
                    card: cards[id],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (canView) ...[
          AppSearchField(
            inset: true,
            hint: '이름, 직급 검색',
            onChanged: (v) => setState(() => _query = v.trim()),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SortStrip(
                  inBox: true,
                  leading: Text(
                    '참여자 (${m.participantIds.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  options: [
                    for (final s in _ParticipantSort.values)
                      PadOption(
                        s.label,
                        selected: _sort == s,
                        onTap: () => setState(() => _sort = s),
                      ),
                  ],
                ),
                const Divider(height: 1),
                if (rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        '해당하는 참여자가 없어요.',
                        style: TextStyle(color: context.palette.muted),
                      ),
                    ),
                  )
                else
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    _Row(
                      me: me,
                      meeting: m,
                      vm: vm,
                      uid: rows[i],
                      card: cards[rows[i]],
                      affiliationNames: affiliationNames,
                      canKick:
                          m.leaderId == me.id ||
                          me.isOperatorView ||
                          // 승인 · 거절 · 추방은 하나의 권한(일정 참여자 승인 · 거절 · 추방)이다.
                          me.canAll(Permission.meetingParticipants),
                    ),
                  ],
              ],
            ),
          ),
        ],
        if (vm.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              vm.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.me,
    required this.meeting,
    required this.vm,
    required this.uid,
    required this.card,
    required this.affiliationNames,
    required this.canKick,
  });

  final Member me;
  final Meeting meeting;
  final MeetingDetailViewModel vm;
  final String uid;
  final PersonCard? card;
  final Map<String, String> affiliationNames;
  final bool canKick;

  @override
  Widget build(BuildContext context) {
    final name = card?.name ?? '';
    final isLeader = uid == meeting.leaderId;
    return PersonRow(
      churchId: me.churchId,
      uid: uid,
      card: card,
      badge: isLeader ? '모임장' : null,
      trailing: [
        if (canKick && !isLeader && !meeting.ended)
          TextButton(
            onPressed: vm.busy
                ? null
                : () async {
                    final ok = await confirmChange(
                      context,
                      title: '${name.isEmpty ? '참여자' : name} 내보내기',
                      confirmLabel: '내보내기',
                      danger: true,
                    );
                    if (ok) await vm.kick(meeting, uid);
                  },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('내보내기'),
          ),
      ],
    );
  }
}

/// 승인 대기 한 줄: 다른 사람 줄과 같은 모양에 거절 · 승인 버튼.
class _PendingRow extends StatelessWidget {
  const _PendingRow({
    required this.me,
    required this.meeting,
    required this.vm,
    required this.uid,
    required this.card,
  });

  final Member me;
  final Meeting meeting;
  final MeetingDetailViewModel vm;
  final String uid;
  final PersonCard? card;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return PersonRow(
      churchId: me.churchId,
      uid: uid,
      card: card,
      trailing: [
        TextButton(
          onPressed: vm.busy ? null : () => vm.reject(meeting, uid),
          style: TextButton.styleFrom(foregroundColor: palette.muted),
          child: const Text('거절'),
        ),
        FilledButton(
          // 정원이 찼으면 승인할 수 없다.
          onPressed: vm.busy || meeting.isFull
              ? null
              : () => vm.approve(meeting, uid),
          child: const Text('승인'),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
