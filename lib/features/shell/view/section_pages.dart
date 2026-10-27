import '../../../data/models/page_layout.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../data/models/church_content.dart';
import '../../admin/view/department_detail_page.dart';
import '../../admin/view/department_manage_page.dart';
import '../../admin/view/church_info_manage_page.dart';
import '../../admin/view/church_join_tab.dart';
import '../../admin/view/church_members_tab.dart';
import '../../home/view/content_detail_page.dart';
import '../../home/view/content_edit_page.dart';
import '../../home/view/content_list_page.dart';
import '../../home/view/content_manage_page.dart';
import '../../home/view/gallery_page.dart';
import '../../home/view/group_hub_page.dart';
import '../../home/view/my_activity_page.dart';
import '../../home/view/page_edit_page.dart';
import '../../home/view/page_list_page.dart';
import '../../home/view/church_page_view.dart';
import 'church_scope.dart';

/// 교회 틀 안에 들어가는 메뉴별 페이지들. 필요한 정보는 [ChurchScope]에서 꺼낸다.

/// 갤러리 탭: 사진첩의 사진만 모아 본다.
class GallerySectionPage extends StatelessWidget {
  const GallerySectionPage({super.key});

  @override
  Widget build(BuildContext context) =>
      GalleryPage(me: ChurchScope.of(context).me);
}

class MemberManageSectionPage extends StatelessWidget {
  const MemberManageSectionPage({super.key});

  @override
  Widget build(BuildContext context) =>
      ChurchMembersTab(me: ChurchScope.of(context).me);
}

class JoinManageSectionPage extends StatelessWidget {
  const JoinManageSectionPage({super.key});

  @override
  Widget build(BuildContext context) =>
      ChurchJoinTab(me: ChurchScope.of(context).me);
}

class DepartmentManageSectionPage extends StatelessWidget {
  const DepartmentManageSectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final me = ChurchScope.of(context).me;
    return DepartmentManagePage(
      me: me,
      onOpen: (d) => context.push(Routes.department(me.churchId, d.id)),
    );
  }
}

class DepartmentDetailSectionPage extends StatelessWidget {
  const DepartmentDetailSectionPage({super.key, required this.departmentId});

  final String departmentId;

  @override
  Widget build(BuildContext context) => DepartmentDetailPage(
    me: ChurchScope.of(context).me,
    departmentId: departmentId,
  );
}

/// 하단 탭 "홈": 홈 그룹 페이지들 (소식과 열람 위주).
class HomeSectionPage extends StatelessWidget {
  const HomeSectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = ChurchScope.of(context);
    return GroupHubPage(
      group: PageGroup.home,
      pages: scope.pages,
      me: scope.me,
      department: scope.department,
    );
  }
}

/// 하단 탭 "기도": 기도 그룹 페이지들 (기도 요청 …).
class IntercessionSectionPage extends StatelessWidget {
  const IntercessionSectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = ChurchScope.of(context);
    return GroupHubPage(
      group: PageGroup.prayer,
      pages: scope.pages,
      me: scope.me,
      department: scope.department,
    );
  }
}

/// 하단 탭 "말씀": 말씀 그룹 페이지들 (말씀 묵상 …).
class WordSectionPage extends StatelessWidget {
  const WordSectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = ChurchScope.of(context);
    return GroupHubPage(
      group: PageGroup.word,
      pages: scope.pages,
      me: scope.me,
      department: scope.department,
    );
  }
}

/// 하단 탭 "내 활동": 기도 · 말씀 페이지 구성에 따라 자동으로 모이는 내 글.
class MineSectionPage extends StatelessWidget {
  const MineSectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = ChurchScope.of(context);
    return MyActivityPage(me: scope.me, pages: scope.pages);
  }
}

/// 교역자가 구성한 페이지 하나 (주소 `/p/{페이지}`). 없는 페이지면 첫째 페이지로 본다.
class PageSectionPage extends StatelessWidget {
  const PageSectionPage({super.key, required this.pageId});

  final String pageId;

  @override
  Widget build(BuildContext context) {
    final scope = ChurchScope.of(context);
    final page =
        scope.pages.where((p) => p.id == pageId).firstOrNull ??
        scope.pages.first;
    return ChurchPageView(
      key: ValueKey('page/${page.id}/${scope.department?.id}'),
      page: page,
      me: scope.me,
      department: scope.department,
    );
  }
}

/// 페이지 편집 (교역자·교회 운영자): 메뉴 페이지 목록.
class PageListSectionPage extends StatelessWidget {
  const PageListSectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = ChurchScope.of(context);
    return PageListPage(me: scope.me, pages: scope.pages);
  }
}

/// 콘텐츠 관리 (교회 운영자): 종류를 주면 그 종류의 글 관리, 없으면 종류 목록.
class ContentEditSectionPage extends StatelessWidget {
  const ContentEditSectionPage({super.key, this.kind});

  final ContentKind? kind;

  @override
  Widget build(BuildContext context) {
    final scope = ChurchScope.of(context);
    final k = kind;
    return k == null
        ? ContentManagePage(me: scope.me)
        : ContentEditPage(me: scope.me, kind: k);
  }
}

/// 한 페이지의 구성 편집.
class PageEditSectionPage extends StatelessWidget {
  const PageEditSectionPage({super.key, required this.pageId, this.draft});

  final String pageId;

  /// 아직 저장하지 않은 새 페이지 (페이지 목록의 "페이지 추가"에서 넘어온다).
  /// 저장 버튼을 눌러야 교회에 만들어진다.
  final PageConfig? draft;

  @override
  Widget build(BuildContext context) {
    final scope = ChurchScope.of(context);
    final d = draft;
    final isNew = d != null && !scope.pages.any((p) => p.id == d.id);
    return PageEditPage(
      me: scope.me,
      pages: isNew ? [...scope.pages, d] : scope.pages,
      pageId: pageId,
      isNew: isNew,
    );
  }
}

/// 메인의 "더보기" 목록.
class ContentListSectionPage extends StatelessWidget {
  const ContentListSectionPage({super.key, required this.kind});

  final ContentKind kind;

  @override
  Widget build(BuildContext context) =>
      ContentListPage(me: ChurchScope.of(context).me, kind: kind);
}

class ContentDetailSectionPage extends StatelessWidget {
  const ContentDetailSectionPage({
    super.key,
    required this.kind,
    required this.contentId,
  });

  final ContentKind kind;
  final String contentId;

  @override
  Widget build(BuildContext context) => ContentDetailPage(
    me: ChurchScope.of(context).me,
    kind: kind,
    contentId: contentId,
  );
}

class ChurchInfoSectionPage extends StatelessWidget {
  const ChurchInfoSectionPage({super.key});

  @override
  Widget build(BuildContext context) =>
      ChurchInfoManagePage(me: ChurchScope.of(context).me);
}
