import '../icons.dart';

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
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
    this.badge = 0,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  /// 0보다 크면 메뉴 오른쪽에 숫자가 나타난다 (예: 인원 관리의 입장 요청 수).
  final int badge;
}

/// 제목이 붙은 메뉴 묶음 (예: "관리").
class SidebarGroup {
  const SidebarGroup({this.title, required this.items});

  final String? title;
  final List<SidebarItem> items;
}

/// 좁은 화면에서 서랍과 계정 띠를 함께 닫는 함수를 안쪽 위젯에 전해 준다.
class _PanelCloser extends InheritedWidget {
  const _PanelCloser({required this.close, required super.child});

  final VoidCallback close;

  static VoidCallback? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PanelCloser>()?.close;

  @override
  bool updateShouldNotify(_PanelCloser old) => false;
}

/// 파이어베이스 콘솔처럼 왼쪽에 앱 이름과 메뉴를 두는 화면 틀.
/// - 넓은 화면: 왼쪽에 메뉴가 항상 보인다.
/// - 좁은 화면: ☰ 버튼을 누르면 왼쪽 메뉴와 오른쪽 계정 띠(기존과 같은 너비)가 함께 나타나 화면 너비를 나눠 채운다.
/// 계정 띠: 프로필 · 로그아웃, 맨 아래에 설정. 넓은 화면에서는 오른쪽에 얇은 띠로 항상 보인다.
class SidebarScaffold extends StatelessWidget {
  const SidebarScaffold({
    super.key,
    required this.groups,
    required this.userName,
    required this.onProfile,
    required this.onSignOut,
    required this.child,
    this.sidebarHeader,
    this.railActions = const [],
    this.tabs = const [],
    this.topBarTrailing,
    this.backgroundColor,
    this.backdrop,
  });

  final List<SidebarGroup> groups;

  /// 상단 바 · 내용 · 하단 바 뒤에 한 장으로 깔리는 배경 (예: 기도 화면의 게시판 무늬).
  /// 있으면 상단 바가 투명해져서 배경이 끊기지 않고 이어진다.
  final Widget? backdrop;

  /// 앱 이름 아래에 놓는 위젯 (예: 지금 보는 교회와 교회 바꾸기).
  final Widget? sidebarHeader;

  /// 오른쪽 계정 띠에서 프로필 아래에 놓는 버튼들 (예: 알림).
  final List<Widget> railActions;

  /// 하단 탭: 같은 크기의 칸으로 나란히 놓인다.
  /// 좁은 화면에서만 아래에 뜨고, 넓은 화면에서는 왼쪽 메뉴 맨 위에 함께 놓인다.
  final List<SidebarItem> tabs;

  /// 위쪽 탭(서랍 버튼이 있는 줄) 오른쪽에 놓는 위젯 (예: 목록 모양 스위치).
  final Widget? topBarTrailing;

  /// 화면 바탕색을 바꾼다 (예: 기도 화면의 게시판 색). 상단 바 · 하단 바까지 같은 색이 되어 배경색이 하나로 보인다.
  final Color? backgroundColor;
  final String userName;
  final VoidCallback onProfile;
  final VoidCallback onSignOut;
  final Widget child;

  static const sidebarWidth = 248.0;
  static const railWidth = 56.0;
  static const menuBarHeight = 48.0;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < kNarrow;
    final panel = _SidebarPanel(
      groups: narrow || tabs.isEmpty
          ? groups
          : [SidebarGroup(items: tabs), ...groups],
      header: sidebarHeader,
      // 서랍 안에서는 메뉴를 고르면 서랍을 닫는다.
      closeOnTap: narrow,
    );
    final rail = AccountRail(
      userName: userName,
      onProfile: onProfile,
      onSignOut: onSignOut,
      actions: railActions,
    );

    final Widget frame;
    if (narrow) {
      frame = _NarrowFrame(
        panel: Material(
          color: context.palette.surface,
          child: SafeArea(child: panel),
        ),
        rail: rail,
        bottomBar: tabs.isEmpty ? null : _PillTabBar(items: tabs),
        topBarTrailing: topBarTrailing,
        backdrop: backdrop,
        child: child,
      );
    } else {
      frame = _WideFrame(
        sidebar: panel,
        rail: rail,
        topBarTrailing: topBarTrailing,
        backdrop: backdrop,
        child: child,
      );
    }
    final color = backgroundColor;
    if (color == null) return frame;
    return Theme(
      data: Theme.of(context).copyWith(scaffoldBackgroundColor: color),
      child: frame,
    );
  }
}

/// 오른쪽 계정 띠: 프로필 사진 · 알림 등 · 로그아웃, 맨 아래에 설정.
/// 교회 안에서는 서랍과 함께 열리고, 교회에 속하지 않았어도(내가 속한 교회 · 교회 탐색) 볼 수 있다.
class AccountRail extends StatelessWidget {
  const AccountRail({
    super.key,
    required this.userName,
    required this.onProfile,
    required this.onSignOut,
    this.actions = const [],
  });

  final String userName;
  final VoidCallback onProfile;
  final VoidCallback onSignOut;

  /// 프로필 아래에 놓는 버튼들 (예: 알림).
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: SidebarScaffold.railWidth,
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
                    ...actions,
                    _LogoutButton(onSignOut: onSignOut),
                    const Spacer(),
                    const _ThemeButton(),
                    const SizedBox(height: 8),
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

/// 화면 모드 버튼: 누르면 라이트와 다크가 바뀐다 (지금 보이는 모드의 반대로).
class _ThemeButton extends StatelessWidget {
  const _ThemeButton();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: dark ? '라이트 모드' : '다크 모드',
      icon: Icon(dark ? AppIcons.sun : AppIcons.moon),
      onPressed: () =>
          AppScope.read(context).themeMode
              .setMode(dark ? ThemeMode.light : ThemeMode.dark),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: '로그아웃',
    icon: const Icon(AppIcons.signOut),
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
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    boxShadow: [
                      BoxShadow(
                        color: palette.brand.withValues(alpha: 0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    AppIcons.handHeart,
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
                    icon: const Icon(AppIcons.x),
                    onPressed: () => _PanelCloser.of(context)?.call(),
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
          if (closeOnTap) _PanelCloser.of(context)?.call();
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
                  borderRadius: BorderRadius.circular(AppRadius.card),
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
              if (item.badge > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppDepth.brand(context),
                      borderRadius: BorderRadius.circular(AppRadius.control),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      child: Text(
                        item.badge > 99 ? '99+' : '${item.badge}',
                        style: TextStyle(
                          color: palette.onBrand,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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

/// 하단 탭: 내용 아래에 떠 있는 알약 모양 바. 칸마다 아이콘과 이름이 있다.
class _PillTabBar extends StatelessWidget {
  const _PillTabBar({required this.items});

  final List<SidebarItem> items;

  static const _bar = 62.0;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.all(Radius.circular(999)),
          border: Border.all(color: palette.border),
          boxShadow: AppShadow.soft(context),
        ),
        child: SizedBox(
          height: _bar,
          child: Row(
            children: [
              for (final item in items) Expanded(child: _SideTab(item: item)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 탭 한 칸: 아이콘 위에 이름. 고른 탭은 포인트색으로 굵게 보인다.
class _SideTab extends StatelessWidget {
  const _SideTab({required this.item});

  final SidebarItem item;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final selected = item.selected;
    final color = selected ? palette.brand : palette.muted;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: item.onTap,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? item.selectedIcon : item.icon,
              size: 22,
              color: color,
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
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
    this.trailing,
    this.transparent = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Widget? trailing;

  /// 뒤에 깔린 배경이 비쳐 보이게 한다.
  final bool transparent;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: transparent
          ? Colors.transparent
          : Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        right: false,
        child: SizedBox(
          height: SidebarScaffold.menuBarHeight,
          child: Row(
            children: [
              IconButton(tooltip: tooltip, icon: Icon(icon), onPressed: onTap),
              const Spacer(),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// 모바일 틀: 위에 메뉴 버튼이 있는 상단바와 내용. 메뉴 버튼을 누르면 왼쪽 메뉴와 오른쪽 계정 띠가
/// 양쪽에서 함께 나타나며, 둘의 너비를 합치면 화면 너비가 된다.
class _NarrowFrame extends StatefulWidget {
  const _NarrowFrame({
    required this.panel,
    required this.rail,
    required this.child,
    this.bottomBar,
    this.topBarTrailing,
    this.backdrop,
  });

  final Widget panel;
  final Widget rail;
  final Widget child;
  final Widget? bottomBar;
  final Widget? topBarTrailing;
  final Widget? backdrop;

  @override
  State<_NarrowFrame> createState() => _NarrowFrameState();
}

class _NarrowFrameState extends State<_NarrowFrame> {
  static const _duration = Duration(milliseconds: 220);

  bool _open = false;

  void _setOpen(bool v) => setState(() => _open = v);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 열려 있을 때 뒤로 가기는 앱을 나가지 않고 메뉴만 닫는다.
      canPop: !_open,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _setOpen(false);
      },
      child: Scaffold(
        body: Stack(
          children: [
            ?widget.backdrop,
            Column(
              children: [
                _TopBar(
                  icon: AppIcons.sidebarSimple,
                  tooltip: '메뉴',
                  onTap: () => _setOpen(true),
                  trailing: widget.topBarTrailing,
                  transparent: widget.backdrop != null,
                ),
                Expanded(child: widget.child),
                ?widget.bottomBar,
              ],
            ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !_open,
                child: LayoutBuilder(
                  builder: (context, box) {
                    final width = box.maxWidth;
                    // 오른쪽 띠는 늘 같은 너비이고, 왼쪽 메뉴가 나머지를 채운다.
                    const right = SidebarScaffold.railWidth;
                    final left = width - right;
                    return _PanelCloser(
                      close: () => _setOpen(false),
                      child: Stack(
                        children: [
                          AnimatedPositioned(
                            duration: _duration,
                            curve: Curves.easeOutCubic,
                            left: _open ? 0 : -left,
                            top: 0,
                            bottom: 0,
                            width: left,
                            child: widget.panel,
                          ),
                          AnimatedPositioned(
                            duration: _duration,
                            curve: Curves.easeOutCubic,
                            right: _open ? 0 : -right,
                            top: 0,
                            bottom: 0,
                            width: right,
                            child: widget.rail,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
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
    this.topBarTrailing,
    this.backdrop,
  });

  final Widget sidebar;
  final Widget rail;
  final Widget child;
  final Widget? topBarTrailing;
  final Widget? backdrop;

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
            child: Stack(
              children: [
                ?widget.backdrop,
                Column(
                  children: [
                    _TopBar(
                      icon: _open
                          ? AppIcons.sidebarSimpleFill
                          : AppIcons.sidebarSimple,
                      tooltip: _open ? '메뉴 접기' : '메뉴 펼치기',
                      onTap: () => setState(() => _open = !_open),
                      trailing: widget.topBarTrailing,
                      transparent: widget.backdrop != null,
                    ),
                    Expanded(child: widget.child),
                  ],
                ),
              ],
            ),
          ),
          widget.rail,
        ],
      ),
    );
  }
}
