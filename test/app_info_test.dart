import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:god_ch/core/layout/app_info_dialog.dart';
import 'package:god_ch/core/theme.dart';

Widget _app(VoidCallback? onInquiry) => MaterialApp(
  theme: buildTheme(Brightness.light),
  home: Builder(
    builder: (context) => Scaffold(
      body: TextButton(
        onPressed: () => showAppInfo(context, onInquiry: onInquiry),
        child: const Text('정보'),
      ),
    ),
  ),
);

void main() {
  testWidgets('앱 정보 창의 문의하기 버튼이 창을 닫고 문의로 보낸다', (tester) async {
    var opened = 0;
    await tester.pumpWidget(_app(() => opened++));
    await tester.tap(find.text('정보'));
    await tester.pumpAndSettle();
    expect(find.text('문의하기'), findsOneWidget);

    await tester.tap(find.text('문의하기'));
    await tester.pumpAndSettle();
    expect(opened, 1);
    // 창은 닫힌다.
    expect(find.text('문의하기'), findsNothing);
    expect(find.text('닫기'), findsNothing);
  });

  testWidgets('문의 길이 없으면(앱 운영자 화면) 문의하기 버튼이 없다', (tester) async {
    await tester.pumpWidget(_app(null));
    await tester.tap(find.text('정보'));
    await tester.pumpAndSettle();
    expect(find.text('문의하기'), findsNothing);
    expect(find.text('닫기'), findsOneWidget);
  });
}
