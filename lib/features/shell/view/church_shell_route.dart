import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../data/models/department.dart';
import '../../auth/view_model/account_view_model.dart';
import '../../church/view/member_gate.dart';
import '../../church/view_model/departments_view_model.dart';
import 'church_shell.dart';

/// 주소 `/churches/:cid/...`의 틀. 승인된 교인인지 확인하고, 주소의 `dept`(부서)를 찾은 뒤
/// 교회 틀을 그린다. 안쪽 페이지는 [child]로 들어온다.
class ChurchShellRoute extends StatelessWidget {
  const ChurchShellRoute({
    super.key,
    required this.churchId,
    required this.section,
    required this.departmentId,
    required this.child,
  });

  final String churchId;
  final ChurchSection section;

  /// 주소의 `?dept=`. 있으면 그 부서 전용 공간으로 본다.
  final String? departmentId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MemberGate(
      churchId: churchId,
      builder: (context, me) => ViewModelBuilder<AccountViewModel>(
        create: (context) => AccountViewModel(AppScope.read(context).auth),
        builder: (context, account) => _WithDepartment(
          churchId: churchId,
          departmentId: departmentId,
          builder: (context, department) => ChurchShell(
            me: me,
            section: section,
            department: department,
            userName: account.userName,
            userEmail: account.userEmail,
            onSignOut: account.signOut,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 주소의 부서 ID로 부서를 찾는다. 없는 부서면 교회 전체로 본다.
class _WithDepartment extends StatelessWidget {
  const _WithDepartment({
    required this.churchId,
    required this.departmentId,
    required this.builder,
  });

  final String churchId;
  final String? departmentId;
  final Widget Function(BuildContext context, Department? department) builder;

  @override
  Widget build(BuildContext context) {
    final id = departmentId;
    if (id == null) return builder(context, null);
    return ViewModelBuilder<DepartmentsViewModel>(
      create: (context) =>
          DepartmentsViewModel(AppScope.read(context).departments, churchId),
      builder: (context, vm) => StreamBuilder<List<Department>>(
        stream: vm.departments,
        builder: (context, snap) {
          if (!snap.hasData && !snap.hasError) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final found = (snap.data ?? const <Department>[])
              .where((d) => d.id == id)
              .firstOrNull;
          return builder(context, found);
        },
      ),
    );
  }
}
