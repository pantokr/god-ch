import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:god_ch/core/theme.dart';
import 'package:god_ch/data/models/page_layout.dart';
import 'package:god_ch/features/home/view/placement_editor.dart';

Future<void> drag(WidgetTester tester, Finder from, Finder to) async {
  final g = await tester.startGesture(tester.getCenter(from));
  await tester.pump(const Duration(milliseconds: 400));
  await g.moveTo(tester.getCenter(to));
  await tester.pump();
  await g.up();
  await tester.pump();
}

void main() {
  testWidgets('배치 설정: 끌어서 위치와 순서를 바꾸고 저장한다', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final pages = [
      const PageConfig(id: 'a', title: '공지'),
      const PageConfig(id: 'b', title: '일정'),
      const PageConfig(id: 'c', title: '갤러리'),
    ];
    List<PageConfig>? saved;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [AppPalette.light]),
        home: Scaffold(
          body: SingleChildScrollView(
            child: PlacementEditor(
              pages: pages,
              focusId: 'a',
              onSave: (next) async {
                saved = next;
                return null;
              },
            ),
          ),
        ),
      ),
    );
    // 바뀐 것이 없으면 저장할 수 없다.
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    // 일정을 왼쪽 버튼 자리로, 갤러리를 좌측 탭으로 끈다.
    await drag(tester, find.text('일정'), find.text('왼쪽 버튼'));
    await drag(tester, find.text('갤러리'), find.textContaining('좌측 탭'));
    // 공지를 일정이 있던 홈의 맨 위가 아니라 맨 끝으로 옮겨도 홈에 남는다.
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(saved, isNotNull);
    PageGroup of(String id) => saved!.firstWhere((p) => p.id == id).group;
    expect(of('a'), PageGroup.home);
    expect(of('b'), PageGroup.left);
    expect(of('c'), PageGroup.drawer);
  });

  testWidgets('배치 설정: 템플릿 페이지는 홈에 놓을 수 없다', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final prayer = PageConfig(
      id: 'p',
      title: '기도',
      group: PageGroup.left,
      blocks: [BlockConfig.template(BlockType.prayer)],
    );
    final pages = [prayer, const PageConfig(id: 'a', title: '공지')];
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [AppPalette.light]),
        home: Scaffold(
          body: SingleChildScrollView(
            child: PlacementEditor(pages: pages, onSave: (_) async => null),
          ),
        ),
      ),
    );
    await drag(tester, find.text('기도'), find.text('공지'));
    // 홈에 놓이지 못하고 왼쪽 버튼에 그대로 있다.
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });
}
