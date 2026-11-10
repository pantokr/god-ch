import '../icons.dart';

import 'package:flutter/material.dart';

import 'app_info_dialog.dart';

import '../../app/app_scope.dart';
import '../theme.dart';
import '../widgets/brand_mark.dart';
import '../widgets/thumbnail_avatar.dart';
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
  const SidebarGroup({this.title, this.panel, required this.items});

  /// 이 묶음이 속한 패널 이름 (예: 일반 · 관리). 이어진 묶음들이 같은 패널이면 패널 제목은 맨 앞에 한 번만 나온다.
  final String? panel;

  final String? title;
  final List<SidebarItem> items;
}

/// 좁은 화면에서 서랍과 계정 띠를 함께 닫는 함수를 안쪽 위젯에 전해 준다.
class PanelCloser extends InheritedWidget {
  const PanelCloser({super.key, required this.close, required super.child});

  final VoidCallback close;

  static VoidCallback? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PanelCloser>()?.close;

  @override
  bool updateShouldNotify(PanelCloser old) => false;
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
    this.userPhotoUrl = '',
    this.sidebarHeader,
    this.railActions = const [],
    this.tabs = const [],
    this.topBarTrailing,
    this.backgroundColor,
    this.backdrop,
    this.onBack,
    this.title,
    this.footer,
  });

  /// 왼쪽 메뉴 맨 아래에 놓는 위젯 (예: 앱 광고).
  final Widget? footer;

  /// 위쪽 바에 놓는 탭 제목 (없으면 비운다).
  final String? title;

  final List<SidebarGroup> groups;

  /// 있으면 위쪽 바에 뒤로가기 버튼이 생기고 좁은 화면의 하단 탭이 사라진다 (탭에 없는 메뉴 화면용).
  final VoidCallback? onBack;

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

  /// 내 프로필 사진 주소 (오른쪽 계정 띠의 둥근 사진).
  final String userPhotoUrl;
  final VoidCallback onProfile;
  final VoidCallback onSignOut;
  final Widget child;

  static const sidebarWidth = 248.0;
  static const railWidth = 56.0;
  static const menuBarHeight = 48.0;

  @override
  Widget build(BuildContext context) {
    final panel = _SidebarPanel(
      groups: groups,
      header: sidebarHeader,
      footer: footer,
      // 서랍 안에서는 메뉴를 고르면 서랍을 닫는다.
      closeOnTap: true,
    );
    final rail = AccountRail(
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      onProfile: onProfile,
      onSignOut: onSignOut,
      actions: railActions,
    );

    // 넓은 화면도 폰과 같은 서랍 방식이다: 버튼 하나로 왼쪽 메뉴와 오른쪽 계정 띠가 함께 열리고 닫힌다.
    final frame = _NarrowFrame(
      panel: Material(
        color: context.palette.surface,
        child: SafeArea(child: panel),
      ),
      rail: rail,
      bottomBar: tabs.isEmpty || onBack != null
          ? null
          : _PillTabBar(items: tabs),
      topBarTrailing: topBarTrailing,
      backdrop: backdrop,
      onBack: onBack,
      title: title,
      child: child,
    );
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
    this.userPhotoUrl = '',
  });

  final String userName;

  /// 내 프로필 사진 주소. 없으면 이름의 머리글자를 보여준다.
  final String userPhotoUrl;
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
                    _AvatarButton(
                      name: userName,
                      url: userPhotoUrl,
                      onTap: onProfile,
                    ),
                    ...actions,
                    _LogoutButton(onSignOut: onSignOut),
                    const Spacer(),
                    // 아래쪽: 화면 모드(야간 모드), 그 아래 맨 아래에 앱 정보.
                    const _ThemeButton(),
                    IconButton(
                      tooltip: '앱 정보',
                      icon: const Icon(AppIcons.info),
                      onPressed: () => showAppInfo(context),
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
  const _AvatarButton({
    required this.name,
    required this.url,
    required this.onTap,
  });

  final String name;
  final String url;
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
          child: ThumbnailAvatar(name: name, url: url, radius: 15),
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
    this.footer,
  });

  final List<SidebarGroup> groups;
  final Widget? header;
  final Widget? footer;
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
                const BrandLogo(size: 44),
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
                    onPressed: () => PanelCloser.of(context)?.call(),
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
                for (var i = 0; i < groups.length; i++) ...[
                  // 패널이 바뀌는 곳에 패널 제목과 구분선을 둔다 (일반 패널 · 관리 패널).
                  // 패널이 하나뿐이면(관리 메뉴가 없는 교인) 제목 없이 메뉴만 보인다.
                  if (groups[i].panel != null &&
                      {for (final g in groups) g.panel}.length > 1 &&
                      (i == 0 || groups[i - 1].panel != groups[i].panel))
                    _PanelHeading(
                      title: groups[i].panel!,
                      first: i == 0,
                      compact: closeOnTap,
                    ),
                  if (groups[i].title != null)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        closeOnTap ? 14 : 24,
                        14,
                        closeOnTap ? 6 : 10,
                      ),
                      child: Text(
                        groups[i].title!,
                        style: TextStyle(
                          color: palette.muted,
                          fontSize: 12,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  for (final item in groups[i].items)
                    _SidebarTile(item: item, closeOnTap: closeOnTap),
                ],
              ],
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: footer,
            ),
        ],
      ),
    );
  }
}

/// 패널 제목: 굵은 이름과 가로 구분선. 패널마다 메뉴가 확실히 나뉘어 보이게 한다.
class _PanelHeading extends StatelessWidget {
  const _PanelHeading({
    required this.title,
    required this.first,
    required this.compact,
  });

  final String title;
  final bool first;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, first ? 4 : (compact ? 20 : 28), 4, 4),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: palette.ink,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Divider(height: 1, color: palette.border)),
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
          if (closeOnTap) PanelCloser.of(context)?.call();
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
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
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
                          fontWeight: FontWeight.w600,
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

  /// 탭이 화면 아래에서 차지하는 높이 (탭 + 아래 여백). 내용은 이만큼 위로 비켜 선다.
  static const inset = _bar + 12 + 12;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    // 넓은 화면에서는 알약이 내용 너비 안에 가운데로 모인다.
    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kContentWidth),
        child: Padding(
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
                  for (final item in items)
                    Expanded(child: _SideTab(item: item)),
                ],
              ),
            ),
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
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 위쪽 바: 화면 배경색과 같은 색에 메뉴 버튼(메뉴에서 들어온 화면은 뒤로가기)만 있다 (제목은 넣지 않는다).
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.trailing,
    this.onBack,
    this.title,
    this.transparent = false,
  });

  final String? title;

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Widget? trailing;
  final VoidCallback? onBack;

  /// 뒤에 깔린 배경이 비쳐 보이게 한다.
  final bool transparent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: transparent
            ? Colors.transparent
            : Theme.of(context).brightness == Brightness.dark
            ? context.palette.surface
            : Colors.white,
        // 상단 탭 아래에 얇은 테두리선.
        border: Border(bottom: BorderSide(color: context.palette.border)),
      ),
      child: SafeArea(
        bottom: false,
        right: false,
        child: SizedBox(
          height: SidebarScaffold.menuBarHeight,
          child: Row(
            children: [
              // 메뉴에서 들어온 화면은 뒤로가기만 둔다 (메뉴 버튼은 필요 없다).
              if (onBack != null)
                IconButton(
                  tooltip: '뒤로',
                  icon: const Icon(AppIcons.arrowLeft),
                  onPressed: onBack,
                ),
              if (onBack == null)
                IconButton(
                  tooltip: tooltip,
                  icon: Icon(icon),
                  onPressed: onTap,
                ),
              Expanded(
                child: title == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          title!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 17,
                              ),
                        ),
                      ),
              ),
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
    this.onBack,
    this.title,
  });

  final String? title;
  final VoidCallback? onBack;
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
                  onBack: widget.onBack,
                  title: widget.title,
                  transparent: widget.backdrop != null,
                ),
                // 하단 탭은 내용 위에 떠 있다: 알약 둘레는 완전히 투명해서 내용이 그대로 비친다.
                // 내용에는 탭이 가린 만큼 아래 여백을 알려 주어(MediaQuery) 목록 끝과 떠 있는 버튼이 탭 위로 올라온다.
                // 위쪽 안전 영역은 상단 바가 이미 쓰므로 내용에서는 뺀다 (작성 페이지 같은 안쪽 화면의 SafeArea가 또 띄우지 않게).
                Expanded(
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: widget.bottomBar == null
                              ? widget.child
                              : Builder(
                                  builder: (context) {
                                    final mq = MediaQuery.of(context);
                                    return MediaQuery(
                                      data: mq.copyWith(
                                        padding: mq.padding.copyWith(
                                          bottom:
                                              mq.padding.bottom +
                                              _PillTabBar.inset,
                                        ),
                                      ),
                                      child: widget.child,
                                    );
                                  },
                                ),
                        ),
                        if (widget.bottomBar != null)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: widget.bottomBar!,
                          ),
                      ],
                    ),
                  ),
                ),
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
                    return PanelCloser(
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
