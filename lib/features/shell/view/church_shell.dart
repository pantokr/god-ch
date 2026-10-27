import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/layout/profile_summary.dart';
import '../../../core/layout/sidebar_scaffold.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/department.dart';
import '../../../data/models/member.dart';
import '../../../data/models/page_layout.dart';
import '../../admin/view_model/pending_members_view_model.dart';
import '../../home/view_model/church_pages_view_model.dart';
import '../../home/view/department_select.dart';
import '../../home/view_model/department_choice.dart';
import '../../notifications/view/notifications_button.dart';
import '../../settings/view/settings_dialog.dart';
import 'church_scope.dart';

/// 교회(또는 부서) 안의 화면 틀: 왼쪽 메뉴(좁은 화면에서는 서랍) + 본문([child]) + 오른쪽 얇은 계정 띠.
/// 왼쪽 메뉴는 교역자가 구성한 페이지들(메인 · 말씀 묵상 …)과 관리 메뉴다.
/// 메뉴를 바꾸면 주소가 바뀌므로 브라우저 뒤로가기로 이전 메뉴에 돌아갈 수 있다.
class ChurchShell extends StatelessWidget {
  const ChurchShell({
    super.key,
    required this.me,
    required this.section,
    required this.userName,
    required this.onSignOut,
    required this.child,
    required this.departmentChoice,
    this.pageId,
    this.department,
  });

  final Member me;

  /// 지금 보고 있는 메뉴 (주소에서 읽는다).
  final ChurchSection section;

  /// 페이지 메뉴(`/p/{페이지}`)를 보는 중이면 그 페이지의 ID.
  final String? pageId;

  /// 보고 있는 부서 전용 공간. null이면 교회 전체.
  final Department? department;

  /// 기도 · 말씀 탭에서 지금 고른 부서.
  final DepartmentChoice departmentChoice;
  final String userName;
  final VoidCallback onSignOut;
  final Widget child;

  static const _labels = {
    ChurchSection.mine: '내 활동',
    ChurchSection.gallery: '갤러리',
    ChurchSection.content: '페이지 편집',
    ChurchSection.contents: '콘텐츠 관리',
    ChurchSection.members: '교회 회원 관리',
    ChurchSection.join: '교회 입장 관리',
    ChurchSection.info: '교회 정보 관리',
    ChurchSection.departments: '부서 관리',
  };

  static const _icons = {
    ChurchSection.mine: (Icons.person_outline, Icons.person),
    ChurchSection.gallery: (Icons.photo_library_outlined, Icons.photo_library),
    ChurchSection.content: (Icons.edit_note_outlined, Icons.edit_note),
    ChurchSection.contents: (
      Icons.collections_bookmark_outlined,
      Icons.collections_bookmark,
    ),
    ChurchSection.members: (Icons.people_outline, Icons.people),
    ChurchSection.join: (Icons.vpn_key_outlined, Icons.vpn_key),
    ChurchSection.info: (Icons.church_outlined, Icons.church),
    ChurchSection.departments: (Icons.groups_outlined, Icons.groups),
  };

  /// 교역자 이상에게 보이는 메뉴: 인원 · 입장 · 글 게시(콘텐츠) · 부서 (조회와 교역자 업무).
  static const _staffOnly = [
    ChurchSection.members,
    ChurchSection.join,
    ChurchSection.contents,
    ChurchSection.departments,
  ];

  /// 교회 관리자에게만 보이는 메뉴: 앱을 고치는 일 (페이지 편집 · 교회 정보).
  static const _adminOnly = [ChurchSection.content, ChurchSection.info];

  SidebarItem _item(BuildContext context, ChurchSection s, {int badge = 0}) =>
      SidebarItem(
        label: _labels[s]!,
        icon: _icons[s]!.$1,
        selectedIcon: _icons[s]!.$2,
        selected: s == section,
        onTap: () => context.go(Routes.section(me.churchId, s)),
        badge: badge,
      );

  /// 하단 탭 한 칸. 지금 보는 곳이 선택된다.
  SidebarItem _tab(
    BuildContext context,
    String label,
    ChurchSection target,
    IconData icon,
    IconData selectedIcon,
  ) => SidebarItem(
    label: label,
    icon: icon,
    selectedIcon: selectedIcon,
    selected: section == target,
    onTap: () =>
        context.go(Routes.section(me.churchId, target, dept: department?.id)),
  );

  @override
  Widget build(BuildContext context) {
    // 권한이 없는 메뉴 주소로 들어왔다면 메인으로 보낸다 (예: 교인이 인원 관리 주소를 직접 열었을 때).
    if ((_staffOnly.contains(section) && !me.isStaff) ||
        (_adminOnly.contains(section) && !me.isAdmin)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(Routes.home(me.churchId));
      });
    }

    return ViewModelBuilder<ChurchPagesViewModel>(
      key: ValueKey(me.churchId),
      create: (context) =>
          ChurchPagesViewModel(AppScope.read(context).pageLayouts, me.churchId),
      builder: (context, pagesVm) => StreamBuilder<List<PageConfig>>(
        stream: pagesVm.pages,
        // 불러오는 동안, 또는 불러오지 못해도 기본 구성으로 메뉴가 비지 않게 한다.
        initialData: PageConfig.defaults,
        builder: (context, snap) {
          final pages = snap.data ?? PageConfig.defaults;
          Widget frame(int pending) => SidebarScaffold(
            userName: userName,
            onProfile: () =>
                context.push(Routes.account, extra: profileDetailsOf(me)),
            onSettings: () => showSettingsDialog(context),
            onSignOut: onSignOut,
            // 위쪽 탭(서랍 버튼 줄) 오른쪽: 기도 · 말씀 탭에서는 볼 부서를 고른다.
            topBarTrailing:
                section == ChurchSection.intercession ||
                    section == ChurchSection.word
                ? DepartmentSelect(
                    group: section == ChurchSection.intercession
                        ? PageGroup.prayer
                        : PageGroup.word,
                    me: me,
                    choice: departmentChoice,
                  )
                : null,
            railActions: [
              NotificationsButton(
                pendingRequests: pending,
                onOpenRequests: () => context.go(
                  Routes.section(me.churchId, ChurchSection.members),
                ),
              ),
            ],
            // 서랍 맨 위: 앱 이름에서 조금 띄워 "내가 속한 교회"를 보여준다.
            sidebarHeader: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                    child: Text(
                      // 앱 개발자가 연 교회는 "내가 속한"이 아니다.
                      me.isOperatorView ? '교회' : '내가 속한 교회',
                      style: TextStyle(
                        color: context.palette.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _ChurchCard(
                    name: me.churchName,
                    department: department?.name,
                    onSwitch: () => me.isOperatorView
                        ? context.go(Routes.adminChurches)
                        : context.push(Routes.churchList),
                  ),
                ],
              ),
            ),
            // 하단 탭은 기도 · 홈(가운데 원형) · 말씀으로 고정이다.
            bottomItems: [
              _tab(
                context,
                '기도',
                ChurchSection.intercession,
                Icons.favorite_border,
                Icons.favorite,
              ),
              _tab(
                context,
                '홈',
                ChurchSection.home,
                Icons.home_outlined,
                Icons.home,
              ),
              _tab(
                context,
                '말씀',
                ChurchSection.word,
                Icons.menu_book_outlined,
                Icons.menu_book,
              ),
            ],
            // 서랍: 내 활동 · 교회 탐색, 교역자에게는 관리 메뉴가 더해진다.
            groups: [
              SidebarGroup(
                items: me.isOperatorView
                    // 앱 개발자: 회원이 아니라 내 활동 · 교회 탐색이 없고, 앱 개발자 화면으로 돌아가는 길이 있다.
                    ? [
                        SidebarItem(
                          label: '앱 개발자 화면',
                          icon: Icons.admin_panel_settings_outlined,
                          selectedIcon: Icons.admin_panel_settings,
                          selected: false,
                          onTap: () => context.go(Routes.admin),
                        ),
                      ]
                    : [
                        _item(context, ChurchSection.mine),
                        SidebarItem(
                          label: '교회 탐색',
                          icon: Icons.explore_outlined,
                          selectedIcon: Icons.explore,
                          selected: false,
                          onTap: () => context.push(Routes.explore),
                        ),
                      ],
              ),
              if (me.isStaff)
                SidebarGroup(
                  title: '관리',
                  items: [
                    // 인원 관리가 관리 메뉴의 첫째다. 입장 요청이 있으면 오른쪽에 숫자가 나온다.
                    _item(context, ChurchSection.members, badge: pending),
                    _item(context, ChurchSection.join),
                    // 교역자 업무: 글 게시(콘텐츠 관리)와 부서 조회.
                    _item(context, ChurchSection.contents),
                    _item(context, ChurchSection.departments),
                    // 앱을 고치는 일은 교회 관리자만: 페이지 편집 · 교회 정보.
                    if (me.isAdmin) _item(context, ChurchSection.content),
                    if (me.isAdmin) _item(context, ChurchSection.info),
                  ],
                ),
            ],
            child: child,
          );

          return ChurchScope(
            me: me,
            department: department,
            userName: userName,
            onSignOut: onSignOut,
            pages: pages,
            departmentChoice: departmentChoice,
            child: me.isStaff
                ? ViewModelBuilder<PendingMembersViewModel>(
                    create: (context) => PendingMembersViewModel(
                      AppScope.read(context).members,
                      me.churchId,
                    ),
                    builder: (context, pvm) => StreamBuilder<int>(
                      stream: pvm.count,
                      initialData: 0,
                      builder: (context, snap) => frame(snap.data ?? 0),
                    ),
                  )
                : frame(0),
          );
        },
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
  ProfileDetail(
    '역할',
    me.isOperatorView
        ? '앱 개발자'
        : switch (me.role) {
            Role.admin => '교회 관리자',
            Role.staff => '교역자',
            Role.member => '교인',
          },
  ),
];
