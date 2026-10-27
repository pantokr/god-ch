import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../auth/view_model/account_view_model.dart';
import 'platform_shell.dart';

/// 주소 `/admin/...`의 틀. 계정 정보를 붙여 운영자 패널 틀을 그린다.
class PlatformShellRoute extends StatelessWidget {
  const PlatformShellRoute({
    super.key,
    required this.section,
    required this.child,
  });

  final PlatformSection section;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<AccountViewModel>(
      create: (context) {
        final scope = AppScope.read(context);
        // 앱 운영자는 교회 회원이 될 수 없다: 예전에 잘못 남은 내 교인 문서를 지운다.
        scope.churchRegistry.removeOwnMemberships().ignore();
        return AccountViewModel(scope.auth);
      },
      builder: (context, account) => PlatformShell(
        section: section,
        userName: account.userName,
        onSignOut: account.signOut,
        child: child,
      ),
    );
  }
}
