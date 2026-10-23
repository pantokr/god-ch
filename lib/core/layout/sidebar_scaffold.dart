import 'package:flutter/material.dart';

import '../theme.dart';
import 'profile_summary.dart';
import 'responsive.dart';

/// 왼쪽 메뉴 한 칸.
class SidebarItem {
  const SidebarItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;
}

/// 제목이 붙은 메뉴 묶음 (예: "교회 관리").
class SidebarGroup {
  const SidebarGroup({this.title, required this.items});

  final String? title;
  final List<SidebarItem> items;
}

/// 파이어베이스 콘솔처럼 왼쪽에 앱 이름과 메뉴를 두는 화면 틀.
/// - 넓은 화면: 왼쪽에 메뉴가 항상 보인다.
/// - 좁은 화면: 상단 바의 ☰ 버튼으로 같은 메뉴를 서랍(드로어)으로 연다.
/// 오른쪽 위에는 계정 메뉴(내 정보 · 화면 모드 · 로그아웃)가 있다.
class SidebarScaffold extends StatelessWidget {
  const SidebarScaffold({
    super.key,
    required this.groups,
    required this.userName,
    required this.userEmail,
    required this.onSignOut,
    required this.child,
    this.sidebarHeader,
    this.title,
    this.onBack,
    this.backLabel = '뒤로',
    this.profileDetails = const [],
    this.profileExtras,
  });

  final List<SidebarGroup> groups;

  /// 있으면 상단 바 왼쪽에 뒤로가기 버튼이 생긴다 (예: 교회 안에서 내 교회 목록으로).
  final VoidCallback? onBack;
  final String backLabel;

  /// 앱 이름 아래에 놓는 위젯 (예: 지금 보는 교회와 교회 바꾸기).
  final Widget? sidebarHeader;

  /// 상단 바의 현재 위치 표시.
  final String? title;
  final String userName;
  final String userEmail;
  final VoidCallback onSignOut;
  final List<ProfileDetail> profileDetails;
  final Widget? profileExtras;
  final Widget child;

  static const sidebarWidth = 248.0;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < kNarrow;
    final topBar = _TopBar(
      title: title,
      onBack: onBack,
      backLabel: backLabel,
      showMenu: narrow,
      userName: userName,
      userEmail: userEmail,
      onSignOut: onSignOut,
      profileDetails: profileDetails,
      profileExtras: profileExtras,
    );
    final panel = _SidebarPanel(
      groups: groups,
      header: sidebarHeader,
      // 서랍 안에서는 메뉴를 고르면 서랍을 닫는다.
      closeOnTap: narrow,
    );

    if (narrow) {
      return Scaffold(
        drawer: Drawer(
          // 모바일에서는 화면 너비를 가득 채운다.
          width: MediaQuery.sizeOf(context).width,
          backgroundColor: context.palette.surface,
          shape: const RoundedRectangleBorder(),
          child: SafeArea(child: panel),
        ),
        body: Column(
          children: [
            topBar,
            Expanded(child: child),
          ],
        ),
      );
    }
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: sidebarWidth,
            decoration: BoxDecoration(
              color: context.palette.surface,
              border: Border(right: BorderSide(color: context.palette.border)),
            ),
            child: panel,
          ),
          Expanded(
            child: Column(
              children: [
                topBar,
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.onBack,
    required this.backLabel,
    required this.showMenu,
    required this.userName,
    required this.userEmail,
    required this.onSignOut,
    required this.profileDetails,
    required this.profileExtras,
  });

  final String? title;
  final VoidCallback? onBack;
  final String backLabel;
  final bool showMenu;
  final String userName;
  final String userEmail;
  final VoidCallback onSignOut;
  final List<ProfileDetail> profileDetails;
  final Widget? profileExtras;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: EdgeInsets.symmetric(horizontal: showMenu ? 4 : 16),
      decoration: BoxDecoration(
        color: context.palette.surface,
        border: Border(bottom: BorderSide(color: context.palette.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (showMenu)
              Builder(
                builder: (context) => IconButton(
                  tooltip: '메뉴',
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            if (onBack != null)
              IconButton(
                tooltip: backLabel,
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              ),
            Expanded(
              child: Text(
                title ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            AccountMenuButton(
              name: userName,
              email: userEmail,
              onSignOut: onSignOut,
              details: profileDetails,
              extras: profileExtras,
            ),
          ],
        ),
      ),
    );
  }
}

/// 동그란 이름 글자 버튼. 누르면 내 정보 · 로그아웃 메뉴가 열린다.
class AccountMenuButton extends StatelessWidget {
  const AccountMenuButton({
    super.key,
    required this.name,
    required this.email,
    required this.onSignOut,
    this.details = const [],
    this.extras,
  });

  final String name;
  final String email;
  final VoidCallback onSignOut;
  final List<ProfileDetail> details;
  final Widget? extras;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: '계정',
      offset: const Offset(0, 48),
      onSelected: (v) {
        if (v == 'profile') {
          showProfileDialog(
            context,
            name: name,
            email: email,
            details: details,
            extras: extras,
          );
        }
        if (v == 'logout') onSignOut();
      },
      itemBuilder: (_) => [
        PopupMenuItem(enabled: false, child: Text(name)),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'profile', child: Text('내 정보 · 화면 모드')),
        const PopupMenuItem(value: 'logout', child: Text('로그아웃')),
      ],
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          radius: 15,
          backgroundColor: context.palette.brand.withValues(alpha: 0.12),
          child: Text(
            name.isEmpty ? '?' : name.characters.first,
            style: TextStyle(
              fontSize: 13,
              color: context.palette.brand,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarPanel extends StatelessWidget {
  const _SidebarPanel({
    required this.groups,
    required this.header,
    required this.closeOnTap,
  });

  final List<SidebarGroup> groups;
  final Widget? header;
  final bool closeOnTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 앱 이름
        SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.volunteer_activism, color: context.palette.brand),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '함께 지어져 가는 공동체',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontSize: 16),
                  ),
                ),
                // 서랍이 화면을 가득 채우면 바깥을 눌러 닫을 수 없으므로 닫기 버튼을 둔다.
                if (closeOnTap)
                  IconButton(
                    tooltip: '닫기',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.maybePop(context),
                  ),
              ],
            ),
          ),
        ),
        Divider(height: 1, color: context.palette.border),
        if (header != null)
          Padding(padding: const EdgeInsets.all(12), child: header),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            children: [
              for (final g in groups) ...[
                if (g.title != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 6),
                    child: Text(
                      g.title!,
                      style: TextStyle(
                        color: context.palette.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                for (final item in g.items)
                  _SidebarTile(item: item, closeOnTap: closeOnTap),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({required this.item, required this.closeOnTap});

  final SidebarItem item;
  final bool closeOnTap;

  @override
  Widget build(BuildContext context) {
    final selected = item.selected;
    final color = selected ? context.palette.brand : context.palette.ink;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: selected
            ? context.palette.brand.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.control),
          onTap: () {
            if (closeOnTap) Navigator.maybePop(context);
            item.onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(
                  selected ? item.selectedIcon : item.icon,
                  size: 20,
                  color: color,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
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
