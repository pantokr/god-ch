import 'package:flutter/material.dart';

import '../theme.dart';
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

/// 제목이 붙은 메뉴 묶음 (예: "관리").
class SidebarGroup {
  const SidebarGroup({this.title, required this.items});

  final String? title;
  final List<SidebarItem> items;
}

/// 파이어베이스 콘솔처럼 왼쪽에 앱 이름과 메뉴를 두는 화면 틀.
/// - 넓은 화면: 왼쪽에 메뉴가 항상 보인다.
/// - 좁은 화면: 왼쪽 위 상단 탭(바탕 없음)의 ☰ 버튼으로 같은 메뉴를 서랍(드로어)으로 연다.
/// 오른쪽에는 열 필요 없는 얇은 띠가 있다: 프로필 · 로그아웃, 맨 아래에 설정.
class SidebarScaffold extends StatelessWidget {
  const SidebarScaffold({
    super.key,
    required this.groups,
    required this.userName,
    required this.onProfile,
    required this.onSettings,
    required this.onSignOut,
    required this.child,
    this.sidebarHeader,
  });

  final List<SidebarGroup> groups;

  /// 앱 이름 아래에 놓는 위젯 (예: 지금 보는 교회와 교회 바꾸기).
  final Widget? sidebarHeader;
  final String userName;
  final VoidCallback onProfile;
  final VoidCallback onSettings;
  final VoidCallback onSignOut;
  final Widget child;

  static const sidebarWidth = 248.0;
  static const railWidth = 56.0;
  static const menuBarHeight = 48.0;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < kNarrow;
    final panel = _SidebarPanel(
      groups: groups,
      header: sidebarHeader,
      // 서랍 안에서는 메뉴를 고르면 서랍을 닫는다.
      closeOnTap: narrow,
    );
    final rail = Container(
      width: railWidth,
      decoration: BoxDecoration(
        color: context.palette.surface,
        border: Border(left: BorderSide(color: context.palette.border)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _AvatarButton(name: userName, onTap: onProfile),
            _LogoutButton(onSignOut: onSignOut),
            const Spacer(),
            IconButton(
              tooltip: '설정',
              icon: const Icon(Icons.settings_outlined),
              onPressed: onSettings,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
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
        body: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  // 서랍을 여는 버튼: 바탕 없이 왼쪽 위에 얹힌 얇은 상단 탭.
                  SafeArea(
                    bottom: false,
                    right: false,
                    child: SizedBox(
                      height: menuBarHeight,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Builder(
                          builder: (context) => IconButton(
                            tooltip: '메뉴',
                            icon: const Icon(Icons.menu),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
            rail,
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
              color: _warmPaper(context),
              border: Border(right: BorderSide(color: context.palette.border)),
            ),
            child: panel,
          ),
          Expanded(child: child),
          rail,
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: '로그아웃',
    icon: const Icon(Icons.logout),
    onPressed: onSignOut,
  );
}

/// 동그란 프로필 버튼. 누르면 내 정보 · 화면 모드 대화상자가 열린다.
class _AvatarButton extends StatelessWidget {
  const _AvatarButton({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: Tooltip(
        message: '내 정보',
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
      ),
    );
  }
}

/// 사이드바 바탕: 종이 색에 금빛을 아주 살짝 섞어 따뜻하게.
Color _warmPaper(BuildContext context) => Color.alphaBlend(
  context.palette.accent.withValues(alpha: 0.07),
  context.palette.surface,
);

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
    final palette = context.palette;
    return ColoredBox(
      color: _warmPaper(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 앱 제목
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              closeOnTap ? 12 : 28,
              12,
              closeOnTap ? 8 : 20,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: palette.brand.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.card + 2),
                  ),
                  child: Icon(
                    Icons.volunteer_activism,
                    size: 24,
                    color: palette.brand,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    '같이',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontSize: 18, height: 1.35),
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
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: header,
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                for (final g in groups) ...[
                  if (g.title != null)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        14,
                        closeOnTap ? 14 : 24,
                        14,
                        closeOnTap ? 6 : 10,
                      ),
                      child: Text(
                        g.title!,
                        style: TextStyle(
                          color: palette.muted,
                          fontSize: 12,
                          letterSpacing: 0.6,
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
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({required this.item, required this.closeOnTap});

  final SidebarItem item;
  final bool closeOnTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final selected = item.selected;
    final color = selected ? palette.brand : palette.ink;
    final radius = BorderRadius.circular(AppRadius.card + 2);
    return Padding(
      padding: EdgeInsets.only(bottom: closeOnTap ? 4 : 6),
      child: Material(
        color: selected ? palette.surface : Colors.transparent,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: selected
                ? Border.all(color: palette.brand.withValues(alpha: 0.28))
                : null,
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: () {
              if (closeOnTap) Navigator.maybePop(context);
              item.onTap();
            },
            child: SizedBox(
              // 서랍(좁은 화면)에서는 관리 메뉴까지 한눈에 보이도록 칸을 낮춘다.
              height: closeOnTap ? 50 : 60,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: selected
                            ? palette.brand.withValues(alpha: 0.14)
                            : palette.border.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                      child: Icon(
                        selected ? item.selectedIcon : item.icon,
                        size: 20,
                        color: selected ? palette.brand : palette.muted,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          color: color,
                          fontSize: 15,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (selected)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: palette.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
