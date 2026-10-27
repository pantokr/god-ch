import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/church_features.dart';
import '../../../data/models/department.dart';
import '../../../data/models/member.dart';
import '../../../data/models/page_layout.dart';
import '../view_model/department_choice.dart';
import '../view_model/group_access_view_model.dart';

/// 기도 · 말씀 탭에서 지금 볼 부서. 소속 부서 중 이 탭을 쓸 수 있는 부서 가운데 반드시 하나가 골라져 있다.
/// ("전체"는 없다.) 선택지가 없으면 null.
Department? chosenDepartment(TabAccess access, DepartmentChoice choice) {
  final options = access.options;
  if (options.isEmpty) return null;
  return options.where((d) => d.id == choice.id).firstOrNull ?? options.first;
}

/// 위쪽 탭(서랍 버튼이 있는 줄) 오른쪽의 부서 선택: 테두리는 없지만 ▾로 눌러서 고르는 곳임을 알 수 있다.
/// 쓸 수 있는 소속 부서가 둘 이상일 때만 고를 수 있고, 하나뿐이면 이름만 보인다. 없으면 아무것도 보이지 않는다.
class DepartmentSelect extends StatelessWidget {
  const DepartmentSelect({
    super.key,
    required this.group,
    required this.me,
    required this.choice,
  });

  final PageGroup group;
  final Member me;
  final DepartmentChoice choice;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<GroupAccessViewModel>(
      key: ValueKey('select/${me.churchId}'),
      create: (context) =>
          GroupAccessViewModel(AppScope.read(context).departments, me.churchId),
      builder: (context, vm) => StreamBuilder<List<Department>>(
        stream: vm.departments,
        builder: (context, depts) => StreamBuilder<ChurchFeatures>(
          stream: vm.features,
          builder: (context, feat) {
            if (!depts.hasData || !feat.hasData) return const SizedBox.shrink();
            final access = feat.data!.accessFor(group, me, depts.data!);
            if (access.blocked || access.options.isEmpty) {
              return const SizedBox.shrink();
            }
            final current = chosenDepartment(access, choice)!;
            final palette = context.palette;
            final style = TextStyle(
              color: palette.ink,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            );
            if (access.options.length == 1) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(current.name, style: style),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: current.id,
                  isDense: true,
                  style: style,
                  icon: Icon(Icons.arrow_drop_down, color: palette.muted),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  items: [
                    for (final d in access.options)
                      DropdownMenuItem(value: d.id, child: Text(d.name)),
                  ],
                  onChanged: choice.select,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
