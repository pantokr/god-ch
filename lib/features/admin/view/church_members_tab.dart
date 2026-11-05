import '../../../core/widgets/app_loader.dart';

import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/affiliation.dart';
import '../../../data/models/member.dart';
import '../../../data/models/position.dart';
import '../view_model/member_admin_view_model.dart';
import 'member_tile.dart';
import '../../../core/widgets/app_inputs.dart';
import '../../../core/widgets/sort_pad.dart';

/// 교회 회원 관리: 앱 운영자의 "회원 관리"와 같은 구성 (제목 → 검색 → 개수 머리글 → 목록).
/// 새로 들어온 인원(승인 대기 · 최근 가입)이 맨 위에 NEW로 나오고, 줄의 "관리"로 상세 관리 창을 연다.
/// 교회 운영자의 인원 관리와 앱 운영자의 교회 상세 화면이 같이 쓴다.
class ChurchMembersTab extends StatefulWidget {
  const ChurchMembersTab({super.key, required this.me});

  final Member me;

  @override
  State<ChurchMembersTab> createState() => _ChurchMembersTabState();
}

class _ChurchMembersTabState extends State<ChurchMembersTab> {
  Member get me => widget.me;

  // 직급 목록은 이름 앞 아이콘에 쓰며 한 번만 구독한다. 읽지 못해도(권한 등) 아이콘만 빠진다.
  late final Stream<List<Position>> _positions = AppScope.read(context)
      .positions
      .positions(widget.me.churchId);

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<MemberAdminViewModel>(
      create: (context) {
        final scope = AppScope.read(context);
        return MemberAdminViewModel(scope.members, scope.affiliations, me);
      },
      builder: (context, vm) => SingleChildScrollView(
        child: PageFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSearchField(
                inset: true,
                hint: '이름, 아이디, 전화번호 검색',
                onChanged: vm.setQuery,
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<Member>>(
                stream: vm.members,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Text('불러오지 못했습니다\n${snap.error}');
                  }
                  if (!snap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: AppLoader()),
                    );
                  }
                  return StreamBuilder<List<Affiliation>>(
                    stream: vm.affiliations,
                    builder: (context, affs) => StreamBuilder<List<Position>>(
                      stream: _positions,
                      builder: (context, pos) => _List(
                        vm: vm,
                        all: snap.data!,
                        affiliations: affs.data ?? const <Affiliation>[],
                        positions: {
                          for (final p in pos.data ?? const <Position>[])
                            p.id: p,
                        },
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({
    required this.vm,
    required this.all,
    required this.affiliations,
    required this.positions,
  });

  /// 직급 아이디 → 직급 (이름 앞 아이콘에 쓴다).
  final Map<String, Position> positions;
  final MemberAdminViewModel vm;
  final List<Member> all;
  final List<Affiliation> affiliations;

  @override
  Widget build(BuildContext context) {
    // 검색은 새로 들어온 인원과 등록된 인원에 똑같이 적용한다.
    final newcomers = vm.newcomers(all).where(vm.matchesQuery).toList();
    final existing = vm.existing(all);
    // 승인을 기다리는 신규 입장 요청은 맨 위 따로, 나머지(최근 가입 포함)는 교회 회원 목록에.
    // 신규 입장 요청은 요청한 순서로 고정한다 (정렬 기준과 상관없이, 먼저 요청한 사람이 위).
    final requests =
        newcomers.where((m) => m.status == MemberStatus.pending).toList()..sort(
          (a, b) => (a.createdAt ?? DateTime.now()).compareTo(
            b.createdAt ?? DateTime.now(),
          ),
        );
    // 최근 가입한 사람도 고른 정렬 기준에 따라 다른 회원과 한 목록에 섞어 정렬한다 (NEW 표시만 따로 붙는다).
    final rows = [
      ...newcomers.where((m) => m.status != MemberStatus.pending),
      ...existing,
    ]..sort(vm.sorter);
    final names = {for (final a in affiliations) a.id: a.name};

    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목은 박스 안 맨 위에 있다.
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BoxTitle('신규 입장 요청 (${requests.length})'),
                const Divider(height: 1),
                if (requests.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        '신규 요청 회원이 없어요.',
                        style: TextStyle(color: context.palette.muted),
                      ),
                    ),
                  )
                else
                  for (var i = 0; i < requests.length; i++) ...[
                    if (i > 0) const Divider(),
                    MemberTile(
                      member: requests[i],
                      position: positions[requests[i].positionId],
                      vm: vm,
                      isNew: true,
                      affiliations: affiliations,
                      affiliationNames: [
                        for (final id in requests[i].affiliationIds)
                          if (names[id] != null) names[id]!,
                      ],
                    ),
                  ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          // 제목 · 정렬 줄 · 목록이 한 박스 안에 있다 (정렬은 신규 입장 요청에는 적용되지 않는다).
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 제목과 정렬 선택 상자가 같은 줄에 있다 (제목 왼쪽, 정렬 오른쪽).
                SortStrip(
                  inBox: true,
                  leading: Text(
                    '교회 회원 (${all.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  options: [
                    for (final s in MemberSort.values)
                      PadOption(
                        s.label,
                        selected: vm.sort == s,
                        onTap: () => vm.setSort(s),
                      ),
                  ],
                ),
                const Divider(height: 1),
                if (rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        all.isEmpty ? '아직 교회에 속한 회원이 없어요.' : '해당하는 회원이 없어요.',
                        style: TextStyle(color: context.palette.muted),
                      ),
                    ),
                  )
                else
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0) const Divider(),
                    MemberTile(
                      member: rows[i],
                      position: positions[rows[i].positionId],
                      vm: vm,
                      isNew: vm.isNewcomer(rows[i]),
                      affiliations: affiliations,
                      affiliationNames: [
                        for (final id in rows[i].affiliationIds)
                          if (names[id] != null) names[id]!,
                      ],
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
        ],
      ),
    );
  }
}

/// 박스 안 맨 위의 제목 줄.
class _BoxTitle extends StatelessWidget {
  const _BoxTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}
