import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/layout/app_dialog.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/department.dart';
import '../../../data/models/member.dart';
import '../view_model/departments_view_model.dart';
import 'department_picker_dialog.dart';

/// 내 교회 한 곳: 교회 전체로 들어가거나, 소속 부서로 바로 들어갈 수 있다.
class ChurchCard extends StatelessWidget {
  const ChurchCard({super.key, required this.member, required this.onOpen});

  final Member member;
  final void Function(Member church, Department? department) onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => onOpen(member, null),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: context.palette.brand.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.control),
                    ),
                    child: Icon(Icons.church, color: context.palette.brand),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.churchName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(switch (member.role) {
                          Role.admin => '교회 운영자',
                          Role.staff => '교역자',
                          Role.member => '교인',
                        }, style: TextStyle(color: context.palette.muted)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward, color: context.palette.muted),
                ],
              ),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _DepartmentChips(member: member, onOpen: onOpen),
          ),
        ],
      ),
    );
  }
}

/// 내가 소속을 선택한 부서 칩과 "부서 선택" 버튼. 소속은 선택 사항이다.
class _DepartmentChips extends StatelessWidget {
  const _DepartmentChips({required this.member, required this.onOpen});

  final Member member;
  final void Function(Member church, Department? department) onOpen;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<DepartmentsViewModel>(
      create: (context) => DepartmentsViewModel(
        AppScope.read(context).departments,
        member.churchId,
      ),
      builder: (context, vm) => StreamBuilder<List<Department>>(
        stream: vm.departments,
        builder: (context, snap) {
          final all = snap.data ?? const <Department>[];
          final mine = all
              .where((d) => member.departmentIds.contains(d.id))
              .toList();
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final d in mine)
                ActionChip(
                  avatar: const Icon(Icons.groups_outlined, size: 18),
                  label: Text(d.name),
                  onPressed: () => onOpen(member, d),
                ),
              TextButton.icon(
                onPressed: snap.hasData
                    ? () => showAppDialog<void>(
                        context,
                        child: DepartmentPickerDialog(
                          member: member,
                          departments: all,
                        ),
                      )
                    : null,
                icon: const Icon(Icons.tune, size: 18),
                label: Text(mine.isEmpty ? '부서 선택 (선택 사항)' : '부서 변경'),
              ),
            ],
          );
        },
      ),
    );
  }
}
