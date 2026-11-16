import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:god_ch/core/exit_guard.dart';
import 'package:god_ch/core/layout/discard_guard.dart';
import 'package:god_ch/core/layout/sub_page.dart';
import 'package:god_ch/core/theme.dart';

void main() {
  testWidgets('교회 틀 안의 저장 화면: 바뀐 내용이 있으면 뒤로 가기가 먼저 묻는다', (tester) async {
    late BuildContext inner;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: ExitGuard(
          child: UnsavedGuard(
            isDirty: () => true,
            child: Builder(
              builder: (context) {
                inner = context;
                return const Scaffold(body: Text('설정'));
              },
            ),
          ),
        ),
      ),
    );
    ExitGuard.back(inner, '/home');
    await tester.pumpAndSettle();
    expect(find.text('작성 취소'), findsOneWidget);
    expect(find.text('나가기'), findsOneWidget);

    // 취소하면 그대로 남는다.
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.text('작성 취소'), findsNothing);
    expect(find.text('설정'), findsOneWidget);
  });

  testWidgets('위로 쌓인 저장 화면: 위쪽 뒤로가기 버튼도 바뀐 내용이 있으면 묻는다', (tester) async {
    var dirty = true;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => context.push('/form'),
              child: const Text('열기'),
            ),
          ),
        ),
        GoRoute(
          path: '/form',
          builder: (context, _) => SubPage(
            title: '',
            barTitle: '폼',
            fallbackLocation: '/',
            child: DiscardGuard(
              isDirty: () => dirty,
              child: const Text('폼 내용'),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: buildTheme(Brightness.light),
        routerConfig: router,
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(find.text('폼 내용'), findsOneWidget);

    // 바뀐 내용이 있으면 먼저 묻고, 취소하면 남는다.
    await tester.tap(find.byTooltip('돌아가기'));
    await tester.pumpAndSettle();
    expect(find.text('작성 취소'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.text('폼 내용'), findsOneWidget);

    // 나가기를 고르면 이전 화면으로 돌아간다.
    await tester.tap(find.byTooltip('돌아가기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('나가기'));
    await tester.pumpAndSettle();
    expect(find.text('폼 내용'), findsNothing);
    expect(find.text('열기'), findsOneWidget);
  });

  testWidgets('바뀐 내용이 없으면 묻지 않고 바로 돌아간다', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => context.push('/form'),
              child: const Text('열기'),
            ),
          ),
        ),
        GoRoute(
          path: '/form',
          builder: (context, _) => SubPage(
            title: '',
            barTitle: '폼',
            fallbackLocation: '/',
            child: DiscardGuard(
              isDirty: () => false,
              child: const Text('폼 내용'),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: buildTheme(Brightness.light),
        routerConfig: router,
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('돌아가기'));
    await tester.pumpAndSettle();
    expect(find.text('작성 취소'), findsNothing);
    expect(find.text('열기'), findsOneWidget);
  });
}
