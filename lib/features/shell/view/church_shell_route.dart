import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../auth/view_model/account_view_model.dart';
import '../../church/view/member_gate.dart';
import 'church_shell.dart';

/// 주소 `/churches/:cid/...`의 틀. 승인된 교인인지 확인한 뒤 교회 틀을 그린다.
/// 안쪽 페이지는 [child]로 들어온다.
class ChurchShellRoute extends StatelessWidget {
  const ChurchShellRoute({
    super.key,
    required this.churchId,
    required this.section,
    required this.child,
  });

  final String churchId;
  final ChurchSection section;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MemberGate(
      churchId: churchId,
      builder: (context, me) => ViewModelBuilder<AccountViewModel>(
        create: (context) => AccountViewModel(AppScope.read(context).auth),
        builder: (context, account) => ChurchShell(
          me: me,
          section: section,
          userName: account.userName,
          onSignOut: account.signOut,
          child: child,
        ),
      ),
    );
  }
}
