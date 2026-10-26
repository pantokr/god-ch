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
/// - 좁은 화면: 상단 바 없이, 내용 위 왼쪽에 뜬 ☰ 버튼으로 같은 메뉴를 서랍(드로어)으로 연다.
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
    this.railActions = const [],
  });

  final List<SidebarGroup> groups;

  /// 앱 이름 아래에 놓는 위젯 (예: 지금 보는 교회와 교회 바꾸기).
  final Widget? sidebarHeader;

  /// 오른쪽 계정 띠에서 프로필 아래에 놓는 버튼들 (예: 알림).
  final List<Widget> railActions;
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
        // 창이 아주 낮아지거나 전환 중에 높이가 거의 0이 되어도 넘치지 않도록, 모자라면 스크롤된다.
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _AvatarButton(name: userName, onTap: onProfile),
                    ...railActions,
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
            ),
          ),
        ),
      ),
    );

    if (narrow) {
      return _NarrowFrame(
        drawer: Drawer(
          // 모바일에서는 화면 너비의 70%만 차지하고, 나머지 바깥을 누르면 닫힌다.
          width: MediaQuery.sizeOf(context).width * 0.7,
          backgroundColor: context.palette.surface,
          shape: const RoundedRectangleBorder(),
          child: SafeArea(child: panel),
        ),
        rail: rail,
        child: child,
      );
    }
    return _WideFrame(sidebar: panel, rail: rail, child: child);
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

/// 사이드바 바탕: 흰 면에 인디고를 아주 살짝 섞어 본문과 구분한다.
Color _warmPaper(BuildContext context) => Color.alphaBlend(
  context.palette.brand.withValues(alpha: 0.05),
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
                    gradient: AppDepth.brand(context),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: palette.brand.withValues(alpha: 0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.volunteer_activism,
                    size: 24,
                    color: palette.onBrand,
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
              padding: const EdgeInsets.fromLTRB(0, 8, 16, 24),
              children: [
                for (final g in groups) ...[
                  if (g.title != null)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
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
    // 선택한 메뉴는 칸을 채우지 않는다: 왼쪽 세로 막대 + 빛나는 그라데이션 아이콘 칩 + 굵은 글자.
    return Padding(
      padding: EdgeInsets.only(bottom: closeOnTap ? 2 : 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card + 2),
        onTap: () {
          if (closeOnTap) Navigator.maybePop(context);
          item.onTap();
        },
        child: SizedBox(
          // 서랍(좁은 화면)에서는 관리 메뉴까지 한눈에 보이도록 칸을 낮춘다.
          height: closeOnTap ? 48 : 56,
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 4,
                height: selected ? 28 : 0,
                decoration: BoxDecoration(
                  gradient: AppDepth.brand(context),
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: selected ? AppDepth.brand(context) : null,
                  color: selected ? null : palette.ink.withValues(alpha: 0.06),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: palette.brand.withValues(alpha: 0.42),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  selected ? item.selectedIcon : item.icon,
                  size: 20,
                  color: selected ? palette.onBrand : palette.muted,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? palette.ink : palette.muted,
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 위쪽 바: 화면 배경색과 같은 색에 메뉴 버튼만 있다 (제목은 넣지 않는다).
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        right: false,
        child: SizedBox(
          height: SidebarScaffold.menuBarHeight,
          child: Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: tooltip,
              icon: Icon(icon),
              onPressed: onTap,
            ),
          ),
        ),
      ),
    );
  }
}

/// 모바일 틀: 위에 메뉴(드로어) 버튼이 있는 상단바, 그 아래에 내용, 오른쪽에 계정 띠.
class _NarrowFrame extends StatelessWidget {
  const _NarrowFrame({
    required this.drawer,
    required this.rail,
    required this.child,
  });

  final Widget drawer;
  final Widget rail;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: drawer,
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Builder(
                  builder: (context) => _TopBar(
                    icon: Icons.menu,
                    tooltip: '메뉴',
                    onTap: () => Scaffold.of(context).openDrawer(),
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
}

/// 데스크탑 틀: 왼쪽 메뉴 + (상단바 + 내용) + 오른쪽 계정 띠.
/// 상단바의 버튼으로 왼쪽 메뉴를 접고 펼 수 있다.
class _WideFrame extends StatefulWidget {
  const _WideFrame({
    required this.sidebar,
    required this.rail,
    required this.child,
  });

  final Widget sidebar;
  final Widget rail;
  final Widget child;

  @override
  State<_WideFrame> createState() => _WideFrameState();
}

class _WideFrameState extends State<_WideFrame> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: _open ? SidebarScaffold.sidebarWidth : 0,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: _warmPaper(context),
              border: _open
                  ? Border(right: BorderSide(color: context.palette.border))
                  : null,
            ),
            // 접히는 동안에도 메뉴가 찌그러지지 않게 원래 너비로 둔다.
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              minWidth: SidebarScaffold.sidebarWidth,
              maxWidth: SidebarScaffold.sidebarWidth,
              child: widget.sidebar,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                _TopBar(
                  icon: _open ? Icons.menu_open : Icons.menu,
                  tooltip: _open ? '메뉴 접기' : '메뉴 펼치기',
                  onTap: () => setState(() => _open = !_open),
                ),
                Expanded(child: widget.child),
              ],
            ),
          ),
          widget.rail,
        ],
      ),
    );
  }
}
