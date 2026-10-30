import '../../../core/widgets/app_loader.dart';

import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/affiliation.dart';
import '../../../data/models/member.dart';
import '../view_model/member_admin_view_model.dart';
import 'member_tile.dart';
import '../../../core/widgets/app_inputs.dart';

/// 교회 회원 관리: 앱 운영자의 "회원 관리"와 같은 구성 (제목 → 검색 → 개수 머리글 → 목록).
/// 새로 들어온 인원(승인 대기 · 최근 가입)이 맨 위에 NEW로 나오고, 줄의 "관리"로 상세 관리 창을 연다.
/// 교회 운영자의 인원 관리와 앱 운영자의 교회 상세 화면이 같이 쓴다.
class ChurchMembersTab extends StatelessWidget {
  const ChurchMembersTab({super.key, required this.me});

  final Member me;

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
              const PageTitle(title: '교회 회원 관리'),
              AppSearchField(hint: '이름, 아이디, 전화번호 검색', onChanged: vm.setQuery),
              const SizedBox(height: 16),
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
                    builder: (context, affs) => _List(
                      vm: vm,
                      all: snap.data!,
                      affiliations: affs.data ?? const <Affiliation>[],
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
  });

  final MemberAdminViewModel vm;
  final List<Member> all;
  final List<Affiliation> affiliations;

  @override
  Widget build(BuildContext context) {
    // 검색은 새로 들어온 인원과 등록된 인원에 똑같이 적용한다.
    final newcomers = vm.newcomers(all).where(vm.matchesQuery).toList();
    final existing = vm.existing(all);
    // 승인을 기다리는 신규 입장 요청은 맨 위 따로, 나머지(최근 가입 포함)는 교회 회원 목록에.
    final requests = newcomers
        .where((m) => m.status == MemberStatus.pending)
        .toList();
    final rows = [
      ...newcomers.where((m) => m.status != MemberStatus.pending),
      ...existing,
    ];
    final recent = rows.length - existing.length;
    final names = {for (final a in affiliations) a.id: a.name};

    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '신규 입장 요청 (${requests.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (requests.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    '신규 요청 회원이 없어요.',
                    style: TextStyle(color: context.palette.muted),
                  ),
                ),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < requests.length; i++) ...[
                    if (i > 0) const Divider(),
                    MemberTile(
                      member: requests[i],
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
          Text(
            '교회 회원 (${all.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    all.isEmpty ? '아직 교회에 속한 회원이 없어요.' : '해당하는 회원이 없어요.',
                    style: TextStyle(color: context.palette.muted),
                  ),
                ),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0) const Divider(),
                    MemberTile(
                      member: rows[i],
                      vm: vm,
                      isNew: i < recent,
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
