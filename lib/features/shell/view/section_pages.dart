import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../data/models/church_content.dart';
import '../../admin/view/admin_page.dart';
import '../../home/view/content_detail_page.dart';
import '../../home/view/content_edit_page.dart';
import '../../home/view/content_list_page.dart';
import '../../home/view/home_page.dart';
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

class ManageSectionPage extends StatelessWidget {
  const ManageSectionPage({super.key});

  @override
  Widget build(BuildContext context) =>
      AdminPage(me: ChurchScope.of(context).me);
}

/// 교회 메인: 공지 캐러셀, 일정, 사진첩, 설교영상, 말씀묵상.
class HomeSectionPage extends StatelessWidget {
  const HomeSectionPage({super.key});

  @override
  Widget build(BuildContext context) =>
      HomePage(me: ChurchScope.of(context).me);
}

/// 메인 페이지 편집 (교역자·교회 운영자).
class ContentEditSectionPage extends StatelessWidget {
  const ContentEditSectionPage({super.key, this.kind});

  final ContentKind? kind;

  @override
  Widget build(BuildContext context) =>
      ContentEditPage(me: ChurchScope.of(context).me, initialKind: kind);
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
