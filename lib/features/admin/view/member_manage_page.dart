import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../data/models/department.dart';
import '../../../data/models/member.dart';
import '../../home/view/content_widgets.dart';
import '../view_model/member_admin_view_model.dart';
import 'invite_code_card.dart';
import 'member_tile.dart';

/// 인원 관리: 초대 코드, 새로 등록된 인원(승인 대기 · 최근 가입), 등록된 인원 조회.
/// 등록된 인원은 이름·전화번호로 찾고, 역할·상태·부서로 거르고, 순서를 바꿔 볼 수 있다.
class MemberManagePage extends StatelessWidget {
  const MemberManagePage({super.key, required this.me});

  final Member me;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<MemberAdminViewModel>(
      create: (context) {
        final scope = AppScope.read(context);
        return MemberAdminViewModel(scope.members, scope.departments, me);
      },
      builder: (context, vm) => StreamBuilder<List<Member>>(
        stream: vm.members,
        builder: (context, snap) {
          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text('불러오지 못했습니다\n${snap.error}'),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return StreamBuilder<List<Department>>(
            stream: vm.departments,
            builder: (context, depts) {
              final departments = depts.data ?? const <Department>[];
              final names = {for (final d in departments) d.id: d.name};
              return _Body(
                me: me,
                vm: vm,
                all: snap.data!,
                departments: departments,
                names: names,
              );
            },
          );
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.me,
    required this.vm,
    required this.all,
    required this.departments,
    required this.names,
  });

  final Member me;
  final MemberAdminViewModel vm;
  final List<Member> all;
  final List<Department> departments;
  final Map<String, String> names;

  List<String> _deptNames(Member m) => [
    for (final id in m.departmentIds)
      if (names[id] != null) names[id]!,
  ];

  @override
  Widget build(BuildContext context) {
    final newcomers = vm.newcomers(all);
    final existing = vm.existing(all);
    final registered = all.where((m) => !vm.isNewcomer(m)).length;

    return SingleChildScrollView(
      child: PageFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageTitle(
              title: '인원 관리',
              subtitle: '새로 등록된 인원을 승인하고, 등록된 인원을 조회해요.',
            ),
            InviteCodeCard(me: me),

            SectionHeader(title: '새로 등록된 인원 (${newcomers.length})'),
            Text(
              '승인을 기다리는 사람과 최근 ${MemberAdminViewModel.newcomerDays}일 안에 가입한 사람이에요.',
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: 12),
            if (newcomers.isEmpty)
              const EmptyHint('새로 등록된 인원이 없어요.')
            else
              Card(
                child: Column(
                  children: [
                    for (var i = 0; i < newcomers.length; i++) ...[
                      if (i > 0) const Divider(),
                      MemberTile(
                        member: newcomers[i],
                        vm: vm,
                        departmentNames: _deptNames(newcomers[i]),
                        isNew: true,
                      ),
                    ],
                  ],
                ),
              ),

            SectionHeader(title: '등록된 인원 ($registered)'),
            _FilterBar(vm: vm, departments: departments),
            const SizedBox(height: 12),
            if (existing.isEmpty)
              EmptyHint(vm.hasFilter ? '조건에 맞는 인원이 없어요.' : '등록된 인원이 없어요.')
            else ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  vm.hasFilter
                      ? '${existing.length}명 (전체 $registered명 중)'
                      : '${existing.length}명',
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
              ),
              Card(
                child: Column(
                  children: [
                    for (var i = 0; i < existing.length; i++) ...[
                      if (i > 0) const Divider(),
                      MemberTile(
                        member: existing[i],
                        vm: vm,
                        departmentNames: _deptNames(existing[i]),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

/// 검색창과 역할 · 상태 · 부서 필터, 정렬. 좁은 화면에서는 줄바꿈된다.
class _FilterBar extends StatefulWidget {
  const _FilterBar({required this.vm, required this.departments});

  final MemberAdminViewModel vm;
  final List<Department> departments;

  @override
  State<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<_FilterBar> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static const _roleLabels = {
    Role.member: '교인',
    Role.staff: '교역자',
    Role.admin: '교회 운영자',
  };
  static const _statusLabels = {
    MemberStatus.approved: '승인됨',
    MemberStatus.pending: '승인 대기',
    MemberStatus.disabled: '비활성',
  };

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _search,
          onChanged: vm.setQuery,
          decoration: InputDecoration(
            hintText: '이름이나 전화번호로 찾기',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(
                    tooltip: '지우기',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _search.clear();
                      vm.setQuery('');
                    },
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _Filter<Role?>(
              label: '역할',
              value: vm.roleFilter,
              options: {null: '전체', ..._roleLabels},
              onChanged: vm.setRoleFilter,
            ),
            _Filter<MemberStatus?>(
              label: '상태',
              value: vm.statusFilter,
              options: {null: '전체', ..._statusLabels},
              onChanged: vm.setStatusFilter,
            ),
            _Filter<String?>(
              label: '부서',
              value: vm.departmentFilter,
              options: {
                null: '전체',
                for (final d in widget.departments) d.id: d.name,
              },
              onChanged: vm.setDepartmentFilter,
            ),
            _Filter<MemberSort>(
              label: '정렬',
              value: vm.sort,
              options: {for (final s in MemberSort.values) s: s.label},
              onChanged: (v) => vm.setSort(v!),
            ),
            if (vm.hasFilter)
              TextButton.icon(
                onPressed: () {
                  _search.clear();
                  vm.clearFilters();
                },
                icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                label: const Text('조건 지우기'),
              ),
          ],
        ),
      ],
    );
  }
}

/// 이름표가 붙은 드롭다운 한 칸. [options]의 키가 값, 값이 보여줄 글자다.
class _Filter<T> extends StatelessWidget {
  const _Filter({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: DropdownButtonFormField<T>(
        initialValue: options.containsKey(value) ? value : null,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
        items: [
          for (final e in options.entries)
            DropdownMenuItem<T>(
              value: e.key,
              child: Text(
                e.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
