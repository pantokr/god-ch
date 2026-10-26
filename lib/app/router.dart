import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/church_content.dart';
import '../data/models/prayer.dart';
import '../features/auth/view/login_page.dart';
import '../features/auth/view/profile_completion_page.dart';
import '../features/auth/view/sign_up_page.dart';
import '../features/church/view/my_churches_route.dart';
import '../features/platform/view/church_detail_route.dart';
import '../features/platform/view/church_registry_page.dart';
import '../features/platform/view/dashboard_page.dart';
import '../features/platform/view/platform_shell_route.dart';
import '../features/platform/view/users_page.dart';
import '../features/prayers/view/prayer_routes.dart';
import '../features/shell/view/church_shell_route.dart';
import '../features/shell/view/section_pages.dart';
import 'routes.dart';
import 'session.dart';

/// 앱의 모든 화면을 주소로 연결한다. 주소가 곧 화면이므로 브라우저의 뒤로가기·앞으로가기·
/// 새로고침·링크 공유가 모두 동작한다. 로그인 상태([SessionNotifier])에 따라 갈 수 있는 주소를 나눈다.
GoRouter buildRouter(SessionNotifier session) {
  return GoRouter(
    refreshListenable: session,
    redirect: (context, state) => sessionRedirect(session.status, state.uri),
    errorBuilder: (context, state) => const _NotFoundPage(),
    routes: [
      GoRoute(path: '/', builder: (context, state) => const _LoadingPage()),

      // ---- 로그인 전후의 안내 화면 ----
      GoRoute(
        path: Routes.loading,
        builder: (context, state) => const _LoadingPage(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: Routes.signUp,
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: Routes.profile,
        builder: (context, state) => const ProfileCompletionPage(),
      ),

      // ---- 회원 ----
      GoRoute(
        path: Routes.churches,
        builder: (context, state) =>
            MyChurchesRoute(showList: state.uri.queryParameters['list'] == '1'),
      ),
      GoRoute(
        path: '/churches/:cid',
        redirect: (context, state) => Routes.home(state.pathParameters['cid']!),
      ),
      // 기도제목 상세·작성·수정은 교회 틀 밖의 전체 화면이다 (뒤로가기로 목록에 돌아온다).
      GoRoute(
        path: '/churches/:cid/prayers/new',
        builder: (context, state) => PrayerCreateRoute(
          churchId: state.pathParameters['cid']!,
          departmentId: state.uri.queryParameters['dept'],
        ),
      ),
      GoRoute(
        path: '/churches/:cid/prayers/:pid',
        builder: (context, state) => PrayerDetailRoute(
          churchId: state.pathParameters['cid']!,
          prayerId: state.pathParameters['pid']!,
          initial: state.extra is Prayer ? state.extra as Prayer : null,
        ),
      ),
      GoRoute(
        path: '/churches/:cid/prayers/:pid/edit',
        builder: (context, state) => PrayerEditRoute(
          churchId: state.pathParameters['cid']!,
          prayerId: state.pathParameters['pid']!,
        ),
      ),
      // 교회 틀(왼쪽 메뉴) 안의 메뉴들.
      ShellRoute(
        builder: (context, state, child) {
          // /churches/{교회}/{메뉴} 에서 교회와 메뉴를 읽는다.
          final segments = state.uri.pathSegments;
          return ChurchShellRoute(
            key: ValueKey(segments[1]),
            churchId: segments[1],
            section:
                ChurchSection.fromPath(
                  segments.length > 2 ? segments[2] : '',
                ) ??
                ChurchSection.home,
            pageId:
                segments.length > 3 && segments[2] == ChurchSection.page.path
                ? segments[3]
                : null,
            departmentId: state.uri.queryParameters['dept'],
            child: child,
          );
        },
        routes: [
          _sectionRoute(ChurchSection.home, const HomeSectionPage()),
          GoRoute(
            path: '/churches/:cid/${ChurchSection.page.path}/:pid',
            pageBuilder: (context, state) => NoTransitionPage(
              key: ValueKey(state.uri.path),
              child: PageSectionPage(pageId: state.pathParameters['pid']!),
            ),
          ),
          _sectionRoute(ChurchSection.feed, const FeedSectionPage()),
          _sectionRoute(ChurchSection.gallery, const GallerySectionPage()),
          _sectionRoute(ChurchSection.mine, const MineSectionPage()),
          _sectionRoute(ChurchSection.posts, const PostManageSectionPage()),
          _sectionRoute(ChurchSection.members, const MemberManageSectionPage()),
          // 예전 "교회 관리" 주소는 인원 관리로 보낸다.
          GoRoute(
            path: '/churches/:cid/manage',
            redirect: (context, state) => Routes.section(
              state.pathParameters['cid']!,
              ChurchSection.members,
            ),
          ),
          GoRoute(
            path: '/churches/:cid/${ChurchSection.departments.path}',
            // 부모와 자식 경로가 한 화면 스택에 함께 쌓이므로, 키는 각자 맞은 주소(matchedLocation)로 둔다.
            // (둘 다 현재 주소 전체를 키로 쓰면 같은 키가 겹쳐 "keyReservation" 오류가 난다.)
            pageBuilder: (context, state) => NoTransitionPage(
              key: ValueKey(state.matchedLocation),
              child: const DepartmentManageSectionPage(),
            ),
            routes: [
              GoRoute(
                path: ':did',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: ValueKey(state.matchedLocation),
                  child: DepartmentDetailSectionPage(
                    departmentId: state.pathParameters['did']!,
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/churches/:cid/${ChurchSection.content.path}/p/:pid',
            pageBuilder: (context, state) => NoTransitionPage(
              key: ValueKey(state.uri.path),
              child: PageEditSectionPage(pageId: state.pathParameters['pid']!),
            ),
          ),
          GoRoute(
            path: '/churches/:cid/${ChurchSection.content.path}',
            pageBuilder: (context, state) => NoTransitionPage(
              key: ValueKey('${state.pathParameters['cid']}/content'),
              child: const PageListSectionPage(),
            ),
          ),
          GoRoute(
            path: '/churches/:cid/${ChurchSection.contents.path}',
            pageBuilder: (context, state) => NoTransitionPage(
              key: ValueKey('${state.pathParameters['cid']}/contents'),
              child: ContentEditSectionPage(
                kind: ContentKind.fromPath(
                  state.uri.queryParameters['kind'] ?? '',
                ),
              ),
            ),
          ),
          // 메인의 "더보기" 목록과 상세. 왼쪽 메뉴는 그대로 둔 채 본문만 바뀐다.
          GoRoute(
            path: '/churches/:cid/c/:kind',
            redirect: (context, state) =>
                ContentKind.fromPath(state.pathParameters['kind']!) == null
                ? Routes.home(state.pathParameters['cid']!)
                : null,
            pageBuilder: (context, state) => NoTransitionPage(
              key: ValueKey(state.matchedLocation),
              child: ContentListSectionPage(
                kind: ContentKind.fromPath(state.pathParameters['kind']!)!,
              ),
            ),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: ValueKey(state.matchedLocation),
                  child: ContentDetailSectionPage(
                    kind: ContentKind.fromPath(state.pathParameters['kind']!)!,
                    contentId: state.pathParameters['id']!,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),

      // ---- 앱 운영자 ----
      GoRoute(
        path: '/admin/churches/:cid',
        builder: (context, state) =>
            ChurchDetailRoute(churchId: state.pathParameters['cid']!),
      ),
      ShellRoute(
        builder: (context, state, child) => PlatformShellRoute(
          section: PlatformSection.fromPath(state.uri.path),
          child: child,
        ),
        routes: [
          _platformRoute(Routes.admin, const DashboardPage()),
          _platformRoute(Routes.adminChurches, const ChurchRegistryPage()),
          _platformRoute(Routes.adminUsers, const UsersPage()),
        ],
      ),
    ],
  );
}

/// 교회 틀 안의 메뉴 한 칸. 메뉴끼리 이동할 때는 화면 전환 효과를 쓰지 않는다.
GoRoute _sectionRoute(ChurchSection section, Widget page) => GoRoute(
  path: '/churches/:cid/${section.path}',
  pageBuilder: (context, state) => NoTransitionPage(
    // 교회가 바뀌면 화면 상태를 새로 시작한다.
    key: ValueKey('${state.pathParameters['cid']}/${section.path}'),
    child: page,
  ),
);

GoRoute _platformRoute(String path, Widget page) => GoRoute(
  path: path,
  pageBuilder: (context, state) =>
      NoTransitionPage(key: ValueKey(path), child: page),
);

/// 로그인 상태에 맞지 않는 주소로 들어오면 알맞은 곳으로 보낸다. 이동할 필요가 없으면 null.
/// 로그인 전에 열려던 주소는 `from`으로 기억해 두었다가 로그인한 뒤 그 주소로 돌려보낸다.
@visibleForTesting
String? sessionRedirect(SessionStatus status, Uri uri) {
  final path = uri.path;
  final from = uri.queryParameters['from'];

  switch (status) {
    case SessionStatus.loading:
      if (path == Routes.loading) return null;
      return Uri(
        path: Routes.loading,
        queryParameters: {'from': uri.toString()},
      ).toString();

    case SessionStatus.signedOut:
      if (Routes.publicPaths.contains(path)) return null;
      final remember = path == '/' || Routes.gatePaths.contains(path)
          ? null
          : uri.toString();
      return Uri(
        path: Routes.login,
        queryParameters: remember == null ? null : {'from': remember},
      ).toString();

    case SessionStatus.needsProfile:
      return path == Routes.profile ? null : Routes.profile;

    case SessionStatus.member:
      if (path == '/' || Routes.gatePaths.contains(path)) {
        return _validFrom(from, '/churches') ?? Routes.churches;
      }
      // 회원은 앱 운영자 패널에 들어갈 수 없다 (실제 권한은 보안 규칙이 막는다).
      if (path.startsWith('/admin')) return Routes.churches;
      return null;

    case SessionStatus.operator:
      if (path == '/' || Routes.gatePaths.contains(path)) {
        return _validFrom(from, '/admin') ?? Routes.admin;
      }
      // 앱 운영자는 교회에 소속되지 않으므로 교회 안 화면이 없다.
      if (path.startsWith('/churches')) return Routes.admin;
      return null;
  }
}

/// 돌아갈 주소가 이 영역 안의 내부 주소일 때만 쓴다 (다른 사이트로 보내지 않기 위해).
String? _validFrom(String? from, String prefix) =>
    from != null && from.startsWith(prefix) ? from : null;

class _LoadingPage extends StatelessWidget {
  const _LoadingPage();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('페이지를 찾을 수 없어요.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('처음으로'),
            ),
          ],
        ),
      ),
    );
  }
}
