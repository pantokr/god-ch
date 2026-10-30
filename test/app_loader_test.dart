import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:god_ch/core/theme.dart';
import 'package:god_ch/core/widgets/app_loader.dart';

Widget _app(Widget child, {bool disableAnimations = false}) => MaterialApp(
  theme: buildTheme(Brightness.light),
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Scaffold(body: child),
  ),
);

void main() {
  testWidgets('자리가 정해지지 않으면 기본 크기로 그려진다', (tester) async {
    await tester.pumpWidget(_app(const Center(child: AppLoader())));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.getSize(find.byType(AppLoader)), const Size(40, 40));
    expect(tester.takeException(), isNull);
  });

  testWidgets('작은 자리에는 그 크기에 맞춰 그려진다', (tester) async {
    await tester.pumpWidget(
      _app(
        const Center(
          child: SizedBox(width: 18, height: 18, child: AppLoader()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.getSize(find.byType(AppLoader)), const Size(18, 18));
  });

  testWidgets('애니메이션을 끄면 움직이지 않고 멈춰 있다', (tester) async {
    await tester.pumpWidget(
      _app(const Center(child: AppLoader()), disableAnimations: true),
    );
    // 멈춘 상태면 프레임이 더 필요하지 않아 pumpAndSettle이 끝난다.
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
