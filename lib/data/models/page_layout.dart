import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_codec.dart';
import 'church_content.dart';

/// 페이지에 쌓을 수 있는 구조(블록)의 종류. 구조마다 쓸 수 있는 자료와 디자인이 정해져 있다.
enum BlockType {
  carousel('carousel', '캐러셀', '큰 이미지가 자동으로 넘어가요.', [
    BlockVariant('banner', '배너'),
    BlockVariant('cards', '카드 슬라이드'),
  ]),
  board('board', '게시판', '글을 목록이나 격자로 보여줘요.', [
    BlockVariant('list', '목록'),
    BlockVariant('grid', '사진 격자'),
    BlockVariant('compact', '간단히'),
  ]),
  schedule('schedule', '일정', '이번 달 일정을 보여줘요.', [
    BlockVariant('calendar', '달력'),
    BlockVariant('agenda', '일정표'),
  ]),
  messenger('messenger', '메신저', '중보기도 요청을 대화처럼 보여줘요.', [
    BlockVariant('cards', '카드'),
    BlockVariant('bubbles', '말풍선'),
  ]);

  const BlockType(this.id, this.label, this.description, this.variants);

  final String id;
  final String label;
  final String description;

  /// 이 구조에서 고를 수 있는 디자인들. 첫째가 기본이다.
  final List<BlockVariant> variants;

  static BlockType fromId(String? id) =>
      values.firstWhere((t) => t.id == id, orElse: () => board);

  /// 이 구조가 보여줄 수 있는 자료. 메신저는 기도제목, 일정은 일정만, 나머지는 모든 콘텐츠.
  List<BlockSource> get sources => switch (this) {
    messenger => [BlockSource.prayers],
    schedule => [BlockSource.events],
    _ => [for (final k in ContentKind.values) BlockSource.fromKind(k)],
  };
}

/// 구조 안의 디자인 한 가지.
class BlockVariant {
  const BlockVariant(this.id, this.label);

  final String id;
  final String label;
}

/// 블록이 보여줄 자료: 콘텐츠 종류(공지·일정·…) 또는 기도제목.
class BlockSource {
  const BlockSource._(this.id, this.label, this.kind);

  factory BlockSource.fromKind(ContentKind k) =>
      BlockSource._(k.collection, k.label, k);

  static const prayers = BlockSource._('prayers', '중보기도 요청', null);
  static final events = BlockSource.fromKind(ContentKind.event);

  final String id;
  final String label;

  /// 콘텐츠 종류. 기도제목이면 null.
  final ContentKind? kind;

  static BlockSource fromId(String? id) {
    if (id == prayers.id) return prayers;
    final k = ContentKind.fromPath(id ?? '');
    return k == null
        ? BlockSource.fromKind(ContentKind.notice)
        : BlockSource.fromKind(k);
  }
}

/// 페이지 안의 구조 한 칸. 위에서 아래로 쌓인다.
class BlockConfig {
  const BlockConfig({
    required this.id,
    required this.type,
    required this.variant,
    required this.source,
    this.title = '',
    this.limit = 5,
  });

  final String id;
  final BlockType type;

  /// 고른 디자인의 id ([BlockType.variants] 중 하나).
  final String variant;
  final BlockSource source;

  /// 구역 제목. 비워 두면 제목 없이 보여준다.
  final String title;

  /// 보여줄 최대 개수.
  final int limit;

  BlockVariant get variantInfo => type.variants.firstWhere(
    (v) => v.id == variant,
    orElse: () => type.variants.first,
  );

  BlockConfig copyWith({
    BlockType? type,
    String? variant,
    BlockSource? source,
    String? title,
    int? limit,
  }) {
    final nextType = type ?? this.type;
    var nextSource = source ?? this.source;
    // 구조를 바꾸면 그 구조가 쓸 수 있는 자료·디자인으로 맞춘다.
    if (!nextType.sources.any((s) => s.id == nextSource.id)) {
      nextSource = nextType.sources.first;
    }
    var nextVariant = variant ?? this.variant;
    if (!nextType.variants.any((v) => v.id == nextVariant)) {
      nextVariant = nextType.variants.first.id;
    }
    return BlockConfig(
      id: id,
      type: nextType,
      variant: nextVariant,
      source: nextSource,
      title: title ?? this.title,
      limit: limit ?? this.limit,
    );
  }

  Json toMap() => {
    'id': id,
    'type': type.id,
    'variant': variant,
    'source': source.id,
    'title': title,
    'limit': limit,
  };

  factory BlockConfig.fromMap(Map<String, dynamic> m) {
    final type = BlockType.fromId(m['type'] as String?);
    var source = BlockSource.fromId(m['source'] as String?);
    if (!type.sources.any((s) => s.id == source.id)) {
      source = type.sources.first;
    }
    final variant = m['variant'] as String?;
    return BlockConfig(
      id: m['id'] as String? ?? '',
      type: type,
      variant: type.variants.any((v) => v.id == variant)
          ? variant!
          : type.variants.first.id,
      source: source,
      title: m['title'] as String? ?? '',
      limit: (m['limit'] as num?)?.toInt().clamp(1, 20) ?? 5,
    );
  }
}

/// 교회 페이지 하나: 사이드 메뉴의 한 칸이자, 위에서 아래로 쌓인 구조들.
class PageConfig {
  const PageConfig({
    required this.id,
    required this.title,
    this.icon = 'home',
    this.blocks = const [],
  });

  final String id;
  final String title;

  /// 메뉴 아이콘 이름 (화면 쪽 `pageIcons`에 있는 이름).
  final String icon;
  final List<BlockConfig> blocks;

  PageConfig copyWith({
    String? title,
    String? icon,
    List<BlockConfig>? blocks,
  }) => PageConfig(
    id: id,
    title: title ?? this.title,
    icon: icon ?? this.icon,
    blocks: blocks ?? this.blocks,
  );

  bool get hasMessenger => blocks.any((b) => b.type == BlockType.messenger);

  factory PageConfig.fromDoc(DocumentSnapshot<Json> doc) {
    final d = doc.data() ?? const {};
    return PageConfig(
      id: doc.id,
      title: d['title'] as String? ?? '',
      icon: d['icon'] as String? ?? 'home',
      blocks: [
        for (final b in (d['blocks'] as List? ?? const []))
          if (b is Map<String, dynamic>) BlockConfig.fromMap(b),
      ],
    );
  }

  /// 아직 한 번도 편집하지 않은 교회가 보는 기본 구성: 메인 · 말씀 묵상 · 중보기도 요청.
  static final defaults = [
    const PageConfig(
      id: 'main',
      title: '메인',
      icon: 'home',
      blocks: [
        BlockConfig(
          id: 'main-notices',
          type: BlockType.carousel,
          variant: 'banner',
          source: BlockSource._('notices', '공지사항', ContentKind.notice),
        ),
        BlockConfig(
          id: 'main-events',
          type: BlockType.schedule,
          variant: 'calendar',
          source: BlockSource._('events', '일정', ContentKind.event),
          title: '일정',
        ),
        BlockConfig(
          id: 'main-photos',
          type: BlockType.carousel,
          variant: 'cards',
          source: BlockSource._('photos', '사진첩', ContentKind.photo),
          title: '사진첩',
          limit: 8,
        ),
        BlockConfig(
          id: 'main-sermons',
          type: BlockType.board,
          variant: 'list',
          source: BlockSource._('sermons', '설교영상', ContentKind.sermon),
          title: '설교영상',
          limit: 3,
        ),
        BlockConfig(
          id: 'main-devotions',
          type: BlockType.board,
          variant: 'list',
          source: BlockSource._('devotions', '말씀묵상', ContentKind.devotion),
          title: '말씀묵상',
          limit: 1,
        ),
      ],
    ),
    const PageConfig(
      id: 'devotion',
      title: '말씀 묵상',
      icon: 'book',
      blocks: [
        BlockConfig(
          id: 'devotion-list',
          type: BlockType.board,
          variant: 'list',
          source: BlockSource._('devotions', '말씀묵상', ContentKind.devotion),
          title: '말씀묵상',
          limit: 10,
        ),
      ],
    ),
    const PageConfig(
      id: 'prayer',
      title: '중보기도 요청',
      icon: 'favorite',
      blocks: [
        BlockConfig(
          id: 'prayer-feed',
          type: BlockType.messenger,
          variant: 'cards',
          source: BlockSource.prayers,
          title: '함께 나누는 기도제목',
          limit: 20,
        ),
      ],
    ),
  ];
}
