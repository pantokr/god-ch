import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:god_ch/core/theme.dart';
import 'package:god_ch/core/widgets/app_date_picker.dart';

Future<void> _open(
  WidgetTester tester,
  TimeOfDay initial,
  void Function(TimeOfDay?) done,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(Brightness.light),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async =>
                done(await showAppTimePicker(context, initialTime: initial)),
            child: const Text('열기'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('열기'));
  await tester.pumpAndSettle();
}

/// 시계판 위에서 [angleDeg](위쪽 0도, 시계 방향) 방향의 자리를 누른다.
Future<void> _tapDial(WidgetTester tester, double angleDeg) async {
  final dial = find.byWidgetPredicate(
    (w) => w is CustomPaint && w.size == const Size(248, 248),
  );
  final center = tester.getCenter(dial);
  final a = angleDeg * math.pi / 180;
  await tester.tapAt(center + Offset(math.sin(a) * 100, -math.cos(a) * 100));
  await tester.pump();
}

void main() {
  testWidgets('시각 고르기: 시계판에서 시 · 분을 고르고 확인하면 돌려준다', (tester) async {
    TimeOfDay? result;
    await _open(tester, const TimeOfDay(hour: 9, minute: 5), (v) => result = v);
    // 처음 시각이 큰 숫자로 보인다.
    expect(find.text('9'), findsWidgets);
    expect(find.text('05'), findsOneWidget);

    await tester.tap(find.text('오후'));
    // 7시 방향(210도)을 누르면 7시, 곧바로 분 화면으로 넘어간다.
    await _tapDial(tester, 210);
    expect(find.text('7'), findsWidgets);
    // 6시 방향(180도)은 30분.
    await _tapDial(tester, 180);
    expect(find.text('30'), findsWidgets);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(result, const TimeOfDay(hour: 19, minute: 30));
  });

  testWidgets('시각 고르기: 취소하면 null', (tester) async {
    TimeOfDay? result = const TimeOfDay(hour: 1, minute: 1);
    await _open(
      tester,
      const TimeOfDay(hour: 12, minute: 0),
      (v) => result = v,
    );
    expect(find.text('00'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });
}
