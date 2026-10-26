import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../data/models/church_content.dart';
import '../../admin/view/department_detail_page.dart';
import '../../admin/view/department_manage_page.dart';
import '../../admin/view/member_manage_page.dart';
import '../../admin/view/post_manage_page.dart';
import '../../home/view/content_detail_page.dart';
import '../../home/view/content_edit_page.dart';
import '../../home/view/content_list_page.dart';
import '../../home/view/content_manage_page.dart';
import '../../home/view/gallery_page.dart';
import '../../home/view/page_edit_page.dart';
import '../../home/view/page_list_page.dart';
import '../../home/view/church_page_view.dart';
import '../../prayers/view/feed_page.dart';
import '../../prayers/view/my_prayers_page.dart';
import 'church_scope.dart';

/// 교회 틀 안에 들어가는 메뉴별 페이지들. 필요한 정보는 [ChurchScope]에서 꺼낸다.

/// 기도제목 피드. 부서를 보는 중이면 그 부서 전용 글만 보여준다.
class FeedSectionPage extends StatelessWidget {
  const FeedSectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = ChurchScope.of(context);
    // 기도제목 상세에서 돌아오는 곳: 메신저 구조가 있는 페이지가 있으면 그 페이지로 보여준다.
    final messenger = scope.pages.where((p) => p.hasMessenger).firstOrNull;
    if (messenger != null) {
      return ChurchPageView(
        key: ValueKey('page/${messenger.id}/${scope.department?.id}'),
        page: messenger,
        me: scope.me,
        department: scope.department,
      );
    }
    return FeedPage(
      // 부서가 바뀌면 목록을 새로 불러온다.
      key: ValueKey('feed/${scope.department?.id}'),
      me: scope.me,
      department: scope.department,
      onWrite: () => context.push(
        Routes.newPrayer(scope.me.churchId, dept: scope.department?.id),
      ),
    );
  }
}

/// 갤러리 탭: 사진첩의 사진만 모아 본다.
class GallerySectionPage extends StatelessWidget {
  const GallerySectionPage({super.key});

  @override
  Widget build(BuildContext context) =>
      GalleryPage(me: ChurchScope.of(context).me);
}

class MineSectionPage extends StatelessWidget {
  const MineSectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = ChurchScope.of(context);
    return MyPrayersPage(
      me: scope.me,
      onWrite: () => context.push(
        Routes.newPrayer(scope.me.churchId, dept: scope.department?.id),
      ),
    );
  }
}

class PostManageSectionPage extends StatelessWidget {
  const PostManageSectionPage({super.key});

  @override
  Widget build(BuildContext context) =>
      PostManagePage(me: ChurchScope.of(context).me);
}

class MemberManageSectionPage extends StatelessWidget {
  const MemberManageSectionPage({super.key});

  @override
  Widget build(BuildContext context) =>
      MemberManagePage(me: ChurchScope.of(context).me);
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

/// 교회 메인: 메뉴의 첫째 페이지를 보여준다.
class HomeSectionPage extends StatelessWidget {
  const HomeSectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = ChurchScope.of(context);
    return ChurchPageView(
      key: ValueKey('page/${scope.pages.first.id}'),
      page: scope.pages.first,
      me: scope.me,
      department: scope.department,
    );
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

/// 페이지 편집 (교역자·교회 운영자): 메뉴 대분류 목록.
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
  const PageEditSectionPage({super.key, required this.pageId});

  final String pageId;

  @override
  Widget build(BuildContext context) {
    final scope = ChurchScope.of(context);
    return PageEditPage(me: scope.me, pages: scope.pages, pageId: pageId);
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
