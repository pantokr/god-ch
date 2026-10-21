import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/department.dart';
import '../../../data/models/member.dart';
import '../view_model/my_departments_view_model.dart';

/// 소속 부서를 고른다. 부서가 없거나 고르지 않아도 된다.
class DepartmentPickerDialog extends StatelessWidget {
  const DepartmentPickerDialog({
    super.key,
    required this.member,
    required this.departments,
  });

  final Member member;
  final List<Department> departments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ViewModelBuilder<MyDepartmentsViewModel>(
      create: (context) =>
          MyDepartmentsViewModel(AppScope.read(context).members, member),
      builder: (context, vm) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${member.churchName} 소속 부서', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text(
            '속하는 부서를 골라 주세요. 선택하지 않아도 괜찮아요.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          if (departments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('아직 만들어진 부서가 없어요. 교역자가 부서를 만들면 선택할 수 있어요.'),
            ),
          for (final d in departments)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(d.name),
              value: vm.isSelected(d.id),
              onChanged: vm.busy ? null : (v) => vm.toggle(d.id, v ?? false),
            ),
          if (vm.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '저장하지 못했습니다: ${vm.error}',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('완료'),
            ),
          ),
        ],
      ),
    );
  }
}
