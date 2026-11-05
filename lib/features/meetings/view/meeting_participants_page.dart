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
import '../../../data/models/person_card.dart';
import '../../people/view/person_avatar.dart';
import '../../people/view/person_popup.dart';
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
          final allowed =
              m != null &&
              (m.leaderId == me.id || me.isAdmin || me.isOperatorView);
          return SubPage(
            title: '참여자',
            fallbackLocation: back,
            child: m == null || !allowed
                ? Padding(
                    padding: const EdgeInsets.all(48),
                    child: Center(
                      child: snap.connectionState == ConnectionState.waiting
                          ? const AppLoader()
                          : const Text('볼 수 없는 목록입니다.'),
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
                        {
                          for (final p in people.data ?? const <PersonCard>[])
                            p.id: p,
                        },
                        {
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
    Meeting m,
    Map<String, PersonCard> cards,
    Map<String, String> affiliationNames,
  ) {
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
        AppSearchField(
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
                  ),
                ],
            ],
          ),
        ),
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
  });

  final Member me;
  final Meeting meeting;
  final MeetingDetailViewModel vm;
  final String uid;
  final PersonCard? card;
  final Map<String, String> affiliationNames;

  @override
  Widget build(BuildContext context) {
    final name = card?.name ?? '';
    final position = card?.positionName ?? '';
    final isLeader = uid == meeting.leaderId;
    // 모임장 · 직급(없으면 역할) · 소속.
    final info = [
      if (isLeader) '모임장',
      if (position.isNotEmpty)
        position
      else if (card != null)
        switch (card!.role) {
          Role.admin => '교회 운영자',
          Role.staff => '교역자',
          Role.member => '교인',
        },
      for (final id in card?.affiliationIds ?? const <String>[])
        if (affiliationNames[id] != null) affiliationNames[id]!,
    ];
    // 버튼이 있든 없든 줄 높이가 같도록 고정한다.
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            PersonTap(
              churchId: me.churchId,
              uid: uid,
              name: name,
              child: PersonAvatar(
                churchId: me.churchId,
                uid: uid,
                name: name.isEmpty ? '?' : name,
                radius: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? '이름 없음' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (info.isNotEmpty)
                    Text(
                      info.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.palette.muted,
                        fontSize: 12.5,
                      ),
                    ),
                ],
              ),
            ),
            if (!isLeader && !meeting.ended)
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
        ),
      ),
    );
  }
}
