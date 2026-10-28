import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// 콘텐츠 관리 목록(/contents) 위에 종류별 화면(/contents?kind=)을 push해도
/// 페이지 키가 겹쳐 오류가 나지 않아야 한다 (쿼리까지 키에 넣는다).
void main() {
  testWidgets('같은 경로 위에 쿼리만 다른 화면을 쌓아도 오류가 없다', (tester) async {
    final router = GoRouter(
      initialLocation: '/churches/c1/contents',
      routes: [
        ShellRoute(
          builder: (context, state, child) => Scaffold(body: child),
          routes: [
            GoRoute(
              path: '/churches/:cid/contents',
              pageBuilder: (context, state) => NoTransitionPage(
                key: ValueKey(state.uri.toString()),
                child: Center(
                  child: Text(
                    state.uri.queryParameters['kind'] ?? '목록',
                    key: ValueKey('page-${state.uri}'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.text('목록'), findsOneWidget);
    router.push('/churches/c1/contents?kind=notices');
    await tester.pumpAndSettle();
    expect(find.text('notices'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
