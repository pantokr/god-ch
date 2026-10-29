import '../core/exit_guard.dart';
import '../core/layout/profile_summary.dart';
import '../core/splash_page.dart';
import '../features/auth/view/account_page.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/prayer.dart';
import '../features/auth/view/login_page.dart';
import '../features/auth/view/profile_completion_page.dart';
import '../features/auth/view/sign_up_page.dart';
import '../features/bible/view/devotion_detail_page.dart';
import '../features/church/view/church_explore_page.dart';
import '../features/church/view/member_gate.dart';
import '../features/meetings/view/meeting_detail_page.dart';
import '../features/church/view/my_churches_route.dart';
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
      GoRoute(path: '/', builder: (context, state) => const SplashPage()),
      GoRoute(
        path: Routes.account,
        builder: (context, state) => AccountPage(
          details: state.extra is List<ProfileDetail>
              ? state.extra as List<ProfileDetail>
              : const [],
        ),
      ),
      GoRoute(
        path: Routes.explore,
        builder: (context, state) => const ChurchExplorePage(),
      ),

      // ---- 로그인 전후의 안내 화면 ----
      GoRoute(
        path: Routes.loading,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const ExitGuard(child: LoginPage()),
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
        builder: (context, state) => ExitGuard(
          child: MyChurchesRoute(
            showList: state.uri.queryParameters['list'] == '1',
          ),
        ),
      ),
      GoRoute(
        path: '/churches/:cid',
        redirect: (context, state) => Routes.home(state.pathParameters['cid']!),
      ),
      // 기도제목 상세·작성·수정은 교회 틀 밖의 전체 화면이다 (뒤로가기로 목록에 돌아온다).
      GoRoute(
        path: '/churches/:cid/prayers/new',
        builder: (context, state) =>
            PrayerCreateRoute(churchId: state.pathParameters['cid']!),
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
      // 말씀 · 모임 상세도 교회 틀 밖의 전체 화면이다 (뒤로가기로 목록에 돌아온다).
      GoRoute(
        path: '/churches/:cid/devotion/:id',
        builder: (context, state) => MemberGate(
          churchId: state.pathParameters['cid']!,
          builder: (context, me) =>
              DevotionDetailPage(me: me, id: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/churches/:cid/meeting/:id',
        builder: (context, state) => MemberGate(
          churchId: state.pathParameters['cid']!,
          builder: (context, me) =>
              MeetingDetailPage(me: me, id: state.pathParameters['id']!),
        ),
      ),
      // 교회 틀(왼쪽 메뉴) 안의 메뉴들.
      ShellRoute(
        builder: (context, state, child) {
          // /churches/{교회}/{메뉴} 에서 교회와 메뉴를 읽는다.
          final segments = state.uri.pathSegments;
          return ExitGuard(
            child: ChurchShellRoute(
              key: ValueKey(segments[1]),
              churchId: segments[1],
              section:
                  ChurchSection.fromPath(
                    segments.length > 2 ? segments[2] : '',
                  ) ??
                  ChurchSection.prayer,
              child: child,
            ),
          );
        },
        routes: [
          _sectionRoute(ChurchSection.prayer, const PrayerSectionPage()),
          _sectionRoute(ChurchSection.meetings, const MeetingsSectionPage()),
          _sectionRoute(ChurchSection.bible, const BibleSectionPage()),
          _sectionRoute(ChurchSection.mine, const MineSectionPage()),
          _sectionRoute(
            ChurchSection.prayerSettings,
            const PrayerSettingsSectionPage(),
          ),
          _sectionRoute(ChurchSection.members, const MemberManageSectionPage()),
          _sectionRoute(ChurchSection.join, const JoinManageSectionPage()),
          _sectionRoute(ChurchSection.info, const ChurchInfoSectionPage()),
          // 예전 주소(홈 · 기도 · 말씀 탭, 페이지, 콘텐츠 관리 등)는 지금의 메뉴로 보낸다.
          for (final old in const [
            'home',
            'left',
            'intercession',
            'content',
            'contents',
            'gallery',
            'manage',
          ])
            GoRoute(
              path: '/churches/:cid/$old',
              redirect: (context, state) => Routes.section(
                state.pathParameters['cid']!,
                old == 'manage' ? ChurchSection.members : ChurchSection.prayer,
              ),
            ),
          for (final old in const ['right', 'word'])
            GoRoute(
              path: '/churches/:cid/$old',
              redirect: (context, state) => Routes.section(
                state.pathParameters['cid']!,
                ChurchSection.bible,
              ),
            ),
        ],
      ),

      // ---- 앱 운영자 ----
      ShellRoute(
        builder: (context, state, child) => ExitGuard(
          child: PlatformShellRoute(
            section: PlatformSection.fromPath(state.uri.path),
            child: child,
          ),
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
      // 앱 개발자는 회원이 아니어도 교회를 열 수 있다. 다만 "내 교회 목록"은 없다.
      if (path == Routes.churches || path == '${Routes.churches}/') {
        return Routes.admin;
      }
      return null;
  }
}

/// 돌아갈 주소가 이 영역 안의 내부 주소일 때만 쓴다 (다른 사이트로 보내지 않기 위해).
String? _validFrom(String? from, String prefix) =>
    from != null && from.startsWith(prefix) ? from : null;

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
