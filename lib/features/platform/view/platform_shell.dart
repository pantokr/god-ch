import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/layout/profile_summary.dart';
import '../../../core/layout/sidebar_scaffold.dart';
import '../../../core/layout/app_dialog.dart';
import '../../auth/view/profile_edit_dialog.dart';
import '../../settings/view/settings_dialog.dart';

/// 앱 운영자 전용 관리자 패널의 틀. 교회에 소속되지 않고, 이 패널 안에서만 움직인다.
/// 왼쪽 메뉴(좁은 화면에서는 서랍)로 이동하며, 메뉴를 바꾸면 주소가 바뀌므로
/// 브라우저 뒤로가기로 이전 메뉴에 돌아갈 수 있다.
class PlatformShell extends StatelessWidget {
  const PlatformShell({
    super.key,
    required this.section,
    required this.userName,
    required this.onSignOut,
    required this.child,
  });

  /// 지금 보고 있는 메뉴 (주소에서 읽는다).
  final PlatformSection section;
  final String userName;
  final VoidCallback onSignOut;
  final Widget child;

  static const _labels = {
    PlatformSection.dashboard: '대시보드',
    PlatformSection.churches: '교회 관리',
    PlatformSection.users: '회원 관리',
  };

  static const _icons = {
    PlatformSection.dashboard: (Icons.dashboard_outlined, Icons.dashboard),
    PlatformSection.churches: (Icons.church_outlined, Icons.church),
    PlatformSection.users: (Icons.people_outline, Icons.people),
  };

  @override
  Widget build(BuildContext context) {
    return SidebarScaffold(
      userName: userName,
      onProfile: () => showAppDialog<void>(
        context,
        maxWidth: 420,
        child: ProfileEditDialog(
          name: userName,
          details: const [ProfileDetail('역할', '앱 운영자')],
        ),
      ),
      onSettings: () => showSettingsDialog(context),
      onSignOut: onSignOut,
      groups: [
        SidebarGroup(
          title: '앱 운영',
          items: [
            for (final s in PlatformSection.values)
              SidebarItem(
                label: _labels[s]!,
                icon: _icons[s]!.$1,
                selectedIcon: _icons[s]!.$2,
                selected: s == section,
                onTap: () => context.go(s.location),
              ),
          ],
        ),
      ],
      child: child,
    );
  }
}
