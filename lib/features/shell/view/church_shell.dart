import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/layout/profile_summary.dart';
import '../../../core/layout/sidebar_scaffold.dart';
import '../../../core/theme.dart';
import '../../../data/models/department.dart';
import '../../../data/models/member.dart';
import '../../settings/view/theme_mode_selector.dart';
import 'church_scope.dart';

/// 교회(또는 부서) 안의 화면 틀: 왼쪽 메뉴(좁은 화면에서는 서랍) + 본문([child]).
/// 메뉴를 바꾸면 주소가 바뀌므로 브라우저 뒤로가기로 이전 메뉴에 돌아갈 수 있다.
class ChurchShell extends StatelessWidget {
  const ChurchShell({
    super.key,
    required this.me,
    required this.section,
    required this.userName,
    required this.userEmail,
    required this.onSignOut,
    required this.child,
    this.department,
  });

  final Member me;

  /// 지금 보고 있는 메뉴 (주소에서 읽는다).
  final ChurchSection section;

  /// 보고 있는 부서 전용 공간. null이면 교회 전체.
  final Department? department;
  final String userName;
  final String userEmail;
  final VoidCallback onSignOut;
  final Widget child;

  static const _labels = {
    ChurchSection.home: '메인',
    ChurchSection.feed: '중보기도',
    ChurchSection.mine: '내 기도제목',
    ChurchSection.content: '메인 페이지 편집',
    ChurchSection.manage: '교회 관리',
  };

  static const _icons = {
    ChurchSection.home: (Icons.home_outlined, Icons.home),
    ChurchSection.feed: (Icons.favorite_border, Icons.favorite),
    ChurchSection.mine: (Icons.person_outline, Icons.person),
    ChurchSection.content: (Icons.edit_note_outlined, Icons.edit_note),
    ChurchSection.manage: (
      Icons.admin_panel_settings_outlined,
      Icons.admin_panel_settings,
    ),
  };

  /// 모두에게 보이는 메뉴와, 교역자·교회 운영자에게만 보이는 메뉴.
  /// (메인의 "더보기"·상세 주소 `/c/...`는 메뉴에 없으므로 "메인"이 선택된 것으로 본다.)
  static const _everyone = [
    ChurchSection.home,
    ChurchSection.feed,
    ChurchSection.mine,
  ];
  static const _staffOnly = [ChurchSection.content, ChurchSection.manage];

  String _location(ChurchSection s) => Routes.section(
    me.churchId,
    s,
    // 부서 공간은 기도제목에만 적용된다.
    dept: s == ChurchSection.feed || s == ChurchSection.mine
        ? department?.id
        : null,
  );

  SidebarItem _item(BuildContext context, ChurchSection s) => SidebarItem(
    label: _labels[s]!,
    icon: _icons[s]!.$1,
    selectedIcon: _icons[s]!.$2,
    selected: s == section,
    onTap: () => context.go(_location(s)),
  );

  @override
  Widget build(BuildContext context) {
    // 권한이 없는 메뉴 주소로 들어왔다면 메인으로 보낸다 (예: 교인이 교회 관리 주소를 직접 열었을 때).
    if (_staffOnly.contains(section) && !me.isStaff) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(Routes.home(me.churchId));
      });
    }

    final dept = department;
    return ChurchScope(
      me: me,
      department: department,
      userName: userName,
      userEmail: userEmail,
      onSignOut: onSignOut,
      child: SidebarScaffold(
        title: dept == null ? me.churchName : '${me.churchName} · ${dept.name}',
        onBack: () => context.go(Routes.churchList),
        backLabel: '내 교회 목록',
        userName: userName,
        userEmail: userEmail,
        onSignOut: onSignOut,
        profileDetails: profileDetailsOf(me),
        profileExtras: const ThemeModeSelector(),
        sidebarHeader: _ChurchCard(
          name: me.churchName,
          department: dept?.name,
          onSwitch: () => context.go(Routes.churchList),
        ),
        groups: [
          SidebarGroup(items: [for (final s in _everyone) _item(context, s)]),
          if (me.isStaff)
            SidebarGroup(
              title: '관리',
              items: [for (final s in _staffOnly) _item(context, s)],
            ),
        ],
        child: child,
      ),
    );
  }
}

/// 왼쪽 메뉴 위의 "지금 보는 교회" 카드와 교회 바꾸기 버튼.
class _ChurchCard extends StatelessWidget {
  const _ChurchCard({
    required this.name,
    required this.onSwitch,
    this.department,
  });

  final String name;
  final String? department;
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: palette.brand.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Icon(Icons.church_outlined, size: 20, color: palette.brand),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (department != null)
                  Text(
                    department!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: palette.muted, fontSize: 12),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: '내 교회 목록',
            icon: const Icon(Icons.unfold_more, size: 20),
            onPressed: onSwitch,
          ),
        ],
      ),
    );
  }
}

/// 내 정보에 보여줄 교회 / 역할 항목.
List<ProfileDetail> profileDetailsOf(Member me) => [
  ProfileDetail('교회', me.churchName),
  ProfileDetail('역할', switch (me.role) {
    Role.admin => '교회 운영자',
    Role.staff => '교역자',
    Role.member => '교인',
  }),
];
