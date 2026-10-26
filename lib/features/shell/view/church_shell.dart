import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/layout/app_dialog.dart';
import '../../../core/layout/profile_summary.dart';
import '../../../core/layout/sidebar_scaffold.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/department.dart';
import '../../../data/models/member.dart';
import '../../../data/models/page_layout.dart';
import '../../auth/view/profile_edit_dialog.dart';
import '../../home/view/page_icons.dart';
import '../../home/view_model/church_pages_view_model.dart';
import '../../notifications/view/notifications_button.dart';
import '../../settings/view/settings_dialog.dart';
import 'church_scope.dart';

/// 교회(또는 부서) 안의 화면 틀: 왼쪽 메뉴(좁은 화면에서는 서랍) + 본문([child]) + 오른쪽 얇은 계정 띠.
/// 왼쪽 메뉴는 교역자가 구성한 페이지들(메인 · 말씀 묵상 · 중보기도 요청 …)과 내 기도제목, 관리 메뉴다.
/// 메뉴를 바꾸면 주소가 바뀌므로 브라우저 뒤로가기로 이전 메뉴에 돌아갈 수 있다.
class ChurchShell extends StatelessWidget {
  const ChurchShell({
    super.key,
    required this.me,
    required this.section,
    required this.userName,
    required this.onSignOut,
    required this.child,
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
  final String userName;
  final VoidCallback onSignOut;
  final Widget child;

  static const _labels = {
    ChurchSection.gallery: '갤러리',
    ChurchSection.mine: '내 기도제목',
    ChurchSection.content: '페이지 편집',
    ChurchSection.contents: '콘텐츠 관리',
    ChurchSection.posts: '게시글 관리',
    ChurchSection.members: '인원 관리',
    ChurchSection.departments: '부서 관리',
  };

  static const _icons = {
    ChurchSection.gallery: (Icons.photo_library_outlined, Icons.photo_library),
    ChurchSection.mine: (Icons.person_outline, Icons.person),
    ChurchSection.content: (Icons.edit_note_outlined, Icons.edit_note),
    ChurchSection.contents: (
      Icons.collections_bookmark_outlined,
      Icons.collections_bookmark,
    ),
    ChurchSection.posts: (Icons.forum_outlined, Icons.forum),
    ChurchSection.members: (Icons.people_outline, Icons.people),
    ChurchSection.departments: (Icons.groups_outlined, Icons.groups),
  };

  static const _staffOnly = [
    ChurchSection.content,
    ChurchSection.posts,
    ChurchSection.members,
    ChurchSection.departments,
  ];

  /// 교회 운영자에게만 보이는 메뉴. 콘텐츠 관리는 교역자가 신경 쓸 일이 아니다.
  static const _adminOnly = [ChurchSection.contents];

  SidebarItem _item(BuildContext context, ChurchSection s) => SidebarItem(
    label: _labels[s]!,
    icon: _icons[s]!.$1,
    selectedIcon: _icons[s]!.$2,
    selected: s == section,
    onTap: () => context.go(
      Routes.section(
        me.churchId,
        s,
        // 부서 공간은 기도제목에만 적용된다.
        dept: s == ChurchSection.mine ? department?.id : null,
      ),
    ),
  );

  /// 페이지 한 칸. 메인 주소(/home)는 첫째 페이지, 중보기도 주소(/prayers)는 메신저 페이지로 본다.
  SidebarItem _pageItem(
    BuildContext context,
    List<PageConfig> pages,
    PageConfig page,
  ) {
    final icon = pageIconOf(page.icon);
    final selected = switch (section) {
      ChurchSection.page => pageId == page.id,
      ChurchSection.home => identical(page, pages.first),
      ChurchSection.feed => identical(
        page,
        pages.firstWhere((p) => p.hasMessenger, orElse: () => pages.first),
      ),
      _ => false,
    };
    return SidebarItem(
      label: page.title,
      icon: icon.outlined,
      selectedIcon: icon.filled,
      selected: selected,
      onTap: () =>
          context.go(Routes.page(me.churchId, page.id, dept: department?.id)),
    );
  }

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
          return ChurchScope(
            me: me,
            department: department,
            userName: userName,
            onSignOut: onSignOut,
            pages: pages,
            child: SidebarScaffold(
              userName: userName,
              onProfile: () => showAppDialog<void>(
                context,
                maxWidth: 420,
                child: ProfileEditDialog(
                  name: userName,
                  details: profileDetailsOf(me),
                ),
              ),
              onSettings: () => showSettingsDialog(context),
              onSignOut: onSignOut,
              railActions: const [NotificationsButton()],
              sidebarHeader: _ChurchCard(
                name: me.churchName,
                department: department?.name,
                onSwitch: () => context.go(Routes.churchList),
              ),
              groups: [
                SidebarGroup(
                  items: [
                    for (final p in pages) _pageItem(context, pages, p),
                    _item(context, ChurchSection.gallery),
                    _item(context, ChurchSection.mine),
                  ],
                ),
                if (me.isStaff)
                  SidebarGroup(
                    title: '관리',
                    items: [
                      _item(context, ChurchSection.content),
                      if (me.isAdmin) _item(context, ChurchSection.contents),
                      _item(context, ChurchSection.posts),
                      _item(context, ChurchSection.members),
                      _item(context, ChurchSection.departments),
                    ],
                  ),
              ],
              child: child,
            ),
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
  ProfileDetail('역할', switch (me.role) {
    Role.admin => '교회 운영자',
    Role.staff => '교역자',
    Role.member => '교인',
  }),
];
