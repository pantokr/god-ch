import 'package:flutter/material.dart';

import '../theme.dart';
import 'profile_summary.dart';
import 'responsive.dart';

class NavItem {
  const NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
}

/// 웹사이트 상단 바.
/// - 넓은 화면: 왼쪽에 로고, 오른쪽에 메뉴 · 내 정보 · 로그아웃을 따로 둔다.
/// - 좁은 화면: 로고만 두고, 메뉴는 화면 하단 탭이 맡는다.
///   [nav]가 비어 있는 화면(하단 탭이 없는 화면)에서는 계정 메뉴를 오른쪽에 둔다.
/// 경로([breadcrumb])는 바 아래 얇은 줄에 보여준다.
class SiteHeader extends StatelessWidget {
  const SiteHeader({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.onSignOut,
    this.profileDetails = const [],
    this.breadcrumb = const [],
    this.nav = const [],
  });

  final String userName;
  final String userEmail;
  final VoidCallback onSignOut;

  /// "내 정보"에 덧붙여 보여줄 항목 (예: 교회, 역할).
  final List<ProfileDetail> profileDetails;
  final List<Widget> breadcrumb;
  final List<NavItem> nav;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < kNarrow;
    final pad = pagePadding(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kContentWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.volunteer_activism,
                        color: AppColors.brand,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '함께 기도해요',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      if (!narrow) ...[
                        for (final n in nav) _NavLink(item: n),
                        if (nav.isNotEmpty) const _VerticalGap(),
                        TextButton.icon(
                          onPressed: () => showProfileDialog(
                            context,
                            name: userName,
                            email: userEmail,
                            details: profileDetails,
                          ),
                          icon: const Icon(Icons.person_outline, size: 18),
                          label: const Text('내 정보'),
                        ),
                        TextButton.icon(
                          onPressed: onSignOut,
                          icon: const Icon(Icons.logout, size: 18),
                          label: const Text('로그아웃'),
                        ),
                      ] else if (nav.isEmpty)
                        _AccountMenu(name: userName, onSignOut: onSignOut),
                    ],
                  ),
                ),
                if (breadcrumb.isNotEmpty)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var i = 0; i < breadcrumb.length; i++) ...[
                          if (i > 0)
                            const Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: AppColors.muted,
                            ),
                          breadcrumb[i],
                        ],
                      ],
                    ),
                  ),
                if (breadcrumb.isNotEmpty) const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 메뉴와 계정 버튼 사이의 구분선.
class _VerticalGap extends StatelessWidget {
  const _VerticalGap();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 12),
    child: SizedBox(height: 24, child: VerticalDivider(width: 1)),
  );
}

class _NavLink extends StatelessWidget {
  const _NavLink({required this.item});

  final NavItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.selected ? AppColors.brand : AppColors.muted;
    return InkWell(
      onTap: item.onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: item.selected ? AppColors.brand : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              item.label,
              style: TextStyle(
                color: color,
                fontWeight: item.selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 좁은 화면에서 하단 탭이 없는 화면(내 교회 목록)에 쓰는 계정 메뉴.
class _AccountMenu extends StatelessWidget {
  const _AccountMenu({required this.name, required this.onSignOut});

  final String name;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: '계정',
      offset: const Offset(0, 48),
      onSelected: (v) {
        if (v == 'logout') onSignOut();
      },
      itemBuilder: (_) => [
        PopupMenuItem(enabled: false, child: Text(name)),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'logout', child: Text('로그아웃')),
      ],
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          radius: 14,
          backgroundColor: AppColors.brand.withValues(alpha: 0.12),
          child: Text(
            name.isEmpty ? '?' : name.characters.first,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.brand,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
