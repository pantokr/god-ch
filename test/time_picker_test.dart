import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:god_ch/core/theme.dart';
import 'package:god_ch/core/widgets/app_date_picker.dart';

void main() {
  testWidgets('시각 고르기: 오후 · 시 · 분 칸을 눌러 고르고 확인하면 돌려준다', (tester) async {
    TimeOfDay? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => result = await showAppTimePicker(
                context,
                initialTime: const TimeOfDay(hour: 9, minute: 5),
              ),
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    // 처음 시각이 머리글에 보인다.
    expect(find.text('오전 9시 5분'), findsOneWidget);

    await tester.tap(find.text('오후'));
    await tester.tap(find.text('7'));
    await tester.tap(find.text('30'));
    await tester.pump();
    expect(find.text('오후 7시 30분'), findsOneWidget);

    // 1분 조절
    await tester.tap(find.byTooltip('1분 후'));
    await tester.pump();
    expect(find.text('오후 7시 31분'), findsOneWidget);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(result, const TimeOfDay(hour: 19, minute: 31));
  });

  testWidgets('시각 고르기: 취소하면 null', (tester) async {
    TimeOfDay? result = const TimeOfDay(hour: 1, minute: 1);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => result = await showAppTimePicker(
                context,
                initialTime: const TimeOfDay(hour: 12, minute: 0),
              ),
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(find.text('오후 12시 0분'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });
}
