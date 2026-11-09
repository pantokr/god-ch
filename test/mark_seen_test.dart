import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:god_ch/app/preferences_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('글을 만드는 중(build)에 읽음을 기록해도 오류가 나지 않고, 듣는 쪽은 그 뒤에 갱신된다', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = PreferencesController(await SharedPreferences.getInstance());
    await tester.pumpWidget(
      MaterialApp(
        home: ListenableBuilder(
          listenable: prefs,
          builder: (context, _) => Text(prefs.seen('p/c/1') ? '읽음' : '신규'),
        ),
      ),
    );
    expect(find.text('신규'), findsOneWidget);

    // 목록(위)이 듣고 있는 동안 글 화면(아래)이 만들어지며 읽음을 기록한다: 예전에는 여기서 오류가 났다.
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            ListenableBuilder(
              listenable: prefs,
              builder: (context, _) => Text(prefs.seen('p/c/1') ? '읽음' : '신규'),
            ),
            Builder(
              builder: (context) {
                prefs.markSeen('p/c/1');
                return const SizedBox();
              },
            ),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.pump();
    expect(find.text('읽음'), findsOneWidget);
  });
}
