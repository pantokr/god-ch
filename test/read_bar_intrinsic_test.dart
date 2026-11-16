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

  testWidgets('본문 앞에 끼워 넣은 신규 표시도 IntrinsicHeight 안에서 오류 없이 그려진다', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        ReadStatusBar.inline(),
                        TextSpan(
                          text: List.filled(
                            3,
                            '기도 내용이 길어서 두 줄이 되어도 표시가 글줄 안에 머문다 ',
                          ).join(),
                        ),
                      ],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  const Text('아래'),
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
