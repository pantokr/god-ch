import 'package:flutter_test/flutter_test.dart';
import 'package:god_ch/data/models/church_content.dart';
import 'package:god_ch/data/models/page_layout.dart';

BlockConfig block(String id, BlockType type) => BlockConfig(
  id: id,
  type: type,
  variant: type.variants.first.id,
  source: type.sources.first,
  title: id,
);

PageConfig page(String id, PageGroup g, [List<BlockType> types = const []]) =>
    PageConfig(
      id: id,
      title: id,
      group: g,
      blocks: [for (final t in types) block('$id-${t.id}', t)],
    );

void main() {
  test('예전 자리 이름은 왼쪽·오른쪽 버튼으로 읽는다', () {
    expect(PageGroup.fromId('prayer'), PageGroup.left);
    expect(PageGroup.fromId('word'), PageGroup.right);
    expect(PageGroup.fromId('drawer'), PageGroup.drawer);
    expect(PageGroup.fromId(null), PageGroup.home);
    expect(PageGroup.drawer.label, '좌측 탭');
  });

  test('한 칸 자리에 놓으면 있던 페이지는 홈으로 밀려난다', () {
    final pages = [
      page('a', PageGroup.left, [BlockType.board]),
      page('b', PageGroup.home, [BlockType.board]),
    ];
    final next = PageConfig.place(pages, 'b', PageGroup.left)!;
    expect(next.firstWhere((p) => p.id == 'b').group, PageGroup.left);
    expect(next.firstWhere((p) => p.id == 'a').group, PageGroup.home);
    expect(PageConfig.slotError(next), isNull);
  });

  test('템플릿 페이지는 홈에 둘 수 없고, 밀려나면 좌측 탭으로 간다', () {
    final prayer = page('p', PageGroup.left, [BlockType.prayer]);
    expect(prayer.hasTemplate, isTrue);
    expect(prayer.canBeIn(PageGroup.home), isFalse);
    final pages = [
      prayer,
      page('b', PageGroup.home, [BlockType.board]),
    ];
    expect(PageConfig.place(pages, 'p', PageGroup.home), isNull);
    final next = PageConfig.place(pages, 'b', PageGroup.left)!;
    expect(next.firstWhere((p) => p.id == 'p').group, PageGroup.drawer);
  });

  test('좌측 탭은 최대 개수까지만 놓인다', () {
    final pages = [
      for (var i = 0; i < PageGroup.maxDrawer; i++)
        page('d$i', PageGroup.drawer),
      page('x', PageGroup.home),
    ];
    expect(PageConfig.place(pages, 'x', PageGroup.drawer), isNull);
    expect(PageConfig.slotError(pages), isNull);
    expect(
      PageConfig.slotError([...pages, page('y', PageGroup.drawer)]),
      isNotNull,
    );
  });

  test('페이지에는 구조 여러 개 또는 템플릿 하나만 들어간다', () {
    final structures = page('s', PageGroup.home, [
      BlockType.board,
      BlockType.schedule,
      BlockType.video,
    ]);
    expect(structures.hasTemplate, isFalse);
    expect(structures.canBeIn(PageGroup.home), isTrue);
    expect(PageConfig.slotError([structures]), isNull);

    final mixed = page('m', PageGroup.left, [
      BlockType.prayer,
      BlockType.board,
    ]);
    expect(PageConfig.slotError([mixed]), isNotNull);
    expect(page('empty', PageGroup.home).blocks, isEmpty);
  });

  test('내 활동은 템플릿 페이지에서 만들어진다', () {
    final pages = [
      page('a', PageGroup.home, [BlockType.board]),
      page('p', PageGroup.left, [BlockType.prayer]),
      page('w', PageGroup.drawer, [BlockType.devotion]),
    ];
    expect(MyActivity.from(pages), [MyActivity.prayer, MyActivity.devotion]);
  });
  test('같은 템플릿은 교회에 하나만 둘 수 있다', () {
    final two = [
      page('p1', PageGroup.left, [BlockType.prayer]),
      page('p2', PageGroup.drawer, [BlockType.prayer]),
    ];
    expect(PageConfig.slotError(two), contains('하나만'));
    expect(
      PageConfig.slotError([
        page('p1', PageGroup.left, [BlockType.prayer]),
        page('w', PageGroup.right, [BlockType.devotion]),
      ]),
      isNull,
    );
  });

  test('시작 구성은 모두 규칙을 지키고 페이지 번호가 겹치지 않는다', () {
    for (final preset in PageConfig.presets) {
      expect(PageConfig.slotError(preset.pages), isNull, reason: preset.label);
      final ids = [for (final p in preset.pages) p.id];
      expect(ids.toSet().length, ids.length, reason: preset.label);
    }
  });

  test('저장된 값에서 페이지를 읽는다: 새 형식과 예전 형식', () {
    final fresh = PageConfig.fromData('a', {
      'title': '소식',
      'group': 'drawer',
      'structures': [
        {'id': 'x', 'type': 'board', 'variant': 'list', 'category': '행사'},
        {'id': 'y', 'type': 'schedule', 'variant': 'calendar'},
      ],
    })!;
    expect(fresh.group, PageGroup.drawer);
    expect(fresh.blocks.length, 2);
    expect(fresh.blocks.first.category, '행사');
    expect(fresh.blocks.first.supportsCategory, isTrue);
    expect(fresh.blocks.last.supportsCategory, isFalse);

    final old = PageConfig.fromData('b', {
      'title': '기도',
      'group': 'prayer',
      'layout': {'id': 'z', 'type': 'prayer', 'variant': 'float'},
    })!;
    expect(old.group, PageGroup.left);
    expect(old.hasTemplate, isTrue);
  });

  test('마지막 저장 시각은 가장 늦은 것이다', () {
    final a = PageConfig(id: 'a', title: 'a', updatedAt: DateTime(2026, 1, 1));
    final b = PageConfig(id: 'b', title: 'b', updatedAt: DateTime(2026, 3, 1));
    expect(PageConfig.versionOf([a, b]), DateTime(2026, 3, 1));
    expect(PageConfig.versionOf([page('c', PageGroup.home)]), isNull);
  });

  test('글이 어느 페이지에 보이는지: 종류와 영역으로 가려낸다', () {
    ChurchContent post(ContentKind k, [String area = '']) => ChurchContent(
      id: 'x',
      kind: k,
      title: 't',
      body: '',
      date: DateTime(2026),
      category: area,
    );
    BlockConfig board(String area) =>
        block('b$area', BlockType.board).copyWith(category: area);
    final all = PageConfig(id: 'all', title: '전체', blocks: [board('')]);
    final events = PageConfig(id: 'ev', title: '행사', blocks: [board('행사')]);
    final pages = [
      all,
      events,
      page('s', PageGroup.home, [BlockType.schedule]),
    ];

    expect(
      PageConfig.showing(pages, post(ContentKind.notice)).map((p) => p.id),
      ['all'],
    );
    expect(
      PageConfig.showing(
        pages,
        post(ContentKind.notice, '행사'),
      ).map((p) => p.id),
      ['all', 'ev'],
    );
    expect(
      PageConfig.showing(pages, post(ContentKind.event)).map((p) => p.id),
      ['s'],
    );
    expect(PageConfig.showing(pages, post(ContentKind.sermon)), isEmpty);
  });

  test('영역은 공지 · 사진첩 · 설교영상에만 있다', () {
    expect(ContentKind.values.where((k) => k.hasAreas), [
      ContentKind.notice,
      ContentKind.photo,
      ContentKind.sermon,
    ]);
  });
}
