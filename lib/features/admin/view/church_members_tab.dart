import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/department.dart';
import '../../../data/models/member.dart';
import '../view_model/member_admin_view_model.dart';
import 'member_tile.dart';

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
        return MemberAdminViewModel(scope.members, scope.departments, me);
      },
      builder: (context, vm) => SingleChildScrollView(
        child: PageFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageTitle(
                title: '교회 회원 관리',
                subtitle: '교회에 속한 회원을 확인하고 수정해요. 개인정보이므로 외부에 공유하지 마세요.',
              ),
              TextField(
                onChanged: vm.setQuery,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: '이름, 아이디, 전화번호 검색',
                ),
              ),
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
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return StreamBuilder<List<Department>>(
                    stream: vm.departments,
                    builder: (context, depts) => _List(
                      vm: vm,
                      all: snap.data!,
                      departments: depts.data ?? const <Department>[],
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
  const _List({required this.vm, required this.all, required this.departments});

  final MemberAdminViewModel vm;
  final List<Member> all;
  final List<Department> departments;

  @override
  Widget build(BuildContext context) {
    // 검색은 새로 들어온 인원과 등록된 인원에 똑같이 적용한다.
    final newcomers = vm.newcomers(all).where(vm.matchesQuery).toList();
    final existing = vm.existing(all);
    final rows = [...newcomers, ...existing];
    final names = {for (final d in departments) d.id: d.name};

    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      isNew: i < newcomers.length,
                      departments: departments,
                      departmentNames: [
                        for (final id in rows[i].departmentIds)
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
