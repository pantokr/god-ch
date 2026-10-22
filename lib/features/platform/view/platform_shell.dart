import 'package:flutter/material.dart';

import '../../../core/layout/profile_summary.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/layout/site_header.dart';
import '../../../core/theme.dart';
import 'church_registry_page.dart';
import 'dashboard_page.dart';
import 'users_page.dart';

/// 앱 운영자 패널의 메뉴.
enum _Section { dashboard, churches, users }

/// 앱 운영자 전용 관리자 패널. 교회에 소속되지 않고, 이 패널 안에서만 움직인다.
/// 넓은 화면에서는 왼쪽 패널로, 좁은 화면에서는 하단 탭으로 이동한다.
class PlatformShell extends StatefulWidget {
  const PlatformShell({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.onSignOut,
  });

  final String userName;
  final String userEmail;
  final VoidCallback onSignOut;

  @override
  State<PlatformShell> createState() => _PlatformShellState();
}

class _PlatformShellState extends State<PlatformShell> {
  _Section _current = _Section.dashboard;

  static const _labels = {
    _Section.dashboard: '대시보드',
    _Section.churches: '교회 관리',
    _Section.users: '회원 관리',
  };

  static const _icons = {
    _Section.dashboard: (Icons.dashboard_outlined, Icons.dashboard),
    _Section.churches: (Icons.church_outlined, Icons.church),
    _Section.users: (Icons.people_outline, Icons.people),
  };

  Widget _page() => switch (_current) {
    _Section.dashboard => DashboardPage(
      onOpenChurches: () => setState(() => _current = _Section.churches),
    ),
    _Section.churches => const ChurchRegistryPage(),
    _Section.users => const UsersPage(),
  };

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < kNarrow;
    return Scaffold(
      body: Column(
        children: [
          SiteHeader(
            userName: widget.userName,
            userEmail: widget.userEmail,
            onSignOut: widget.onSignOut,
            profileDetails: const [ProfileDetail('역할', '앱 운영자')],
            // 좁은 화면은 하단 탭이 메뉴를 맡으므로 계정 메뉴만 오른쪽에 둔다.
            nav: const [],
          ),
          Expanded(
            child: narrow
                ? _page()
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: kContentWidth,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SidePanel(
                            current: _current,
                            labels: _labels,
                            icons: _icons,
                            onSelect: (s) => setState(() => _current = s),
                          ),
                          Expanded(child: _page()),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: narrow
          ? NavigationBar(
              selectedIndex: _current.index,
              onDestinationSelected: (i) =>
                  setState(() => _current = _Section.values[i]),
              destinations: [
                for (final s in _Section.values)
                  NavigationDestination(
                    icon: Icon(_icons[s]!.$1),
                    selectedIcon: Icon(_icons[s]!.$2),
                    label: _labels[s]!,
                  ),
              ],
            )
          : null,
    );
  }
}

/// 넓은 화면의 왼쪽 메뉴 패널.
class _SidePanel extends StatelessWidget {
  const _SidePanel({
    required this.current,
    required this.labels,
    required this.icons,
    required this.onSelect,
  });

  final _Section current;
  final Map<_Section, String> labels;
  final Map<_Section, (IconData, IconData)> icons;
  final void Function(_Section) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: EdgeInsets.fromLTRB(pagePadding(context), 28, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 12, bottom: 12),
            child: Text(
              '앱 운영',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (final s in _Section.values)
            _PanelItem(
              label: labels[s]!,
              icon: current == s ? icons[s]!.$2 : icons[s]!.$1,
              selected: current == s,
              onTap: () => onSelect(s),
            ),
        ],
      ),
    );
  }
}

class _PanelItem extends StatelessWidget {
  const _PanelItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.brand : AppColors.ink;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected
            ? AppColors.brand.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.control),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
