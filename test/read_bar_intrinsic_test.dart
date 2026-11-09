import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:god_ch/core/theme.dart';
import 'package:god_ch/core/widgets/read_status_bar.dart';

void main() {
  testWidgets('신규 바는 격자 카드(IntrinsicHeight) 안에서 오류 없이 그려진다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Scaffold(
          body: SizedBox(
            width: 600,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: const [
                          ReadStatusBar.fresh(),
                          Text('본문'),
                          Spacer(),
                          Text('아래'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(ReadStatusBar), findsOneWidget);
  });
}
