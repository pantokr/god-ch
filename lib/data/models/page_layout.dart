import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_codec.dart';
import 'block_style.dart';
import 'church_content.dart';

/// 페이지에 쌓을 수 있는 구조(블록)의 종류. 구조마다 쓸 수 있는 자료와 디자인이 정해져 있다.
enum BlockType {
  board('board', '게시판', '예) 공지사항, 홍보자료', [
    BlockVariant('list', '사진+글 · 목록', '글 + 그림'),
    BlockVariant('tiles', '사진+글 · 카드 격자', '글 + 그림'),
    BlockVariant('cards', '사진+글 · 카드 슬라이드', '글 + 그림'),
    BlockVariant('banner', '사진+글 · 배너', '글 + 그림'),
    BlockVariant('feature', '사진+글 · 큰 사진', '글 + 그림'),
    BlockVariant('text', '글만 · 목록', '글만'),
    BlockVariant('compact', '글만 · 간단히', '글만'),
    BlockVariant('table', '글만 · 표', '글만'),
  ]),
  devotion('devotion', '성경 인용', '예) 오늘의 말씀, 묵상 나눔', [
    // 일체형: 말씀과 내 묵상이 한 카드. 분리형: 말씀 카드와 내 묵상 카드가 따로 (일체형 세 가지에 각각 대응).
    BlockVariant('card', '카드', '일체형'),
    BlockVariant('quote', '인용형', '일체형'),
    BlockVariant('note', '줄 노트형', '일체형'),
    BlockVariant('twin', '두 카드 · 카드', '분리형'),
    BlockVariant('twin_quote', '두 카드 · 인용형', '분리형'),
    BlockVariant('twin_note', '두 카드 · 줄 노트형', '분리형'),
    // 최근 말씀 묵상 세 개를 옆으로 넘겨 본다.
    BlockVariant('carousel', '캐러셀 · 최근 3개', '캐러셀'),
  ]),
  video('video', '유튜브 링크', '예) 설교 영상, 찬양 영상', [
    BlockVariant('cards', '영상 카드', '카드'),
    BlockVariant('list', '영상 목록', '목록'),
    BlockVariant('featured', '큰 영상 + 목록', '목록'),
  ]),
  schedule('schedule', '일정', '예) 예배 일정, 행사 일정', [
    // 모양만 고른다. 색은 스타일(심플·파스텔·네온)과 팔레트로 따로 고른다.
    // 일정표는 스타일에 따라 목록(심플) · 티켓(파스텔) · 타임라인(네온)으로 그려진다.
    BlockVariant('calendar', '달력', '달력'),
    BlockVariant('strip', '날짜 띠', '날짜 띠'),
    BlockVariant('agenda', '일정표', '일정표'),
  ]),
  prayer('prayer', '기도 요청', '예) 중보기도, 기도 나눔', [
    // 최신 기도 요청 몇 장이 공중에 떠다닌다.
    BlockVariant('float', '둥둥 떠다니는 카드', '떠다니는 카드'),
    BlockVariant('cards', '카드 목록', '카드'),
  ]),
  gallery('gallery', '갤러리', '예) 행사 사진, 수련회 앨범', [
    BlockVariant('albums', '앨범 카드', '앨범'),
    // 행사 하나가 한 칸: 대표 사진 한 장 뒤에 사진들이 겹겹이 쌓인 모양.
    BlockVariant('stack', '겹겹이 쌓인 사진', '대표 사진'),
  ]);

  const BlockType(this.id, this.label, this.description, this.variants);

  final String id;
  final String label;
  final String description;

  /// 이 구조에서 고를 수 있는 디자인들. 첫째가 기본이다.
  final List<BlockVariant> variants;

  /// 디자인을 성격별로 묶은 것 (처음 나온 성격 순서, 성격 안에서는 목록 순서).
  /// 디자인 고르기에서 성격마다 한 줄로 늘어놓는다.
  Map<String, List<BlockVariant>> get variantGroups {
    final groups = <String, List<BlockVariant>>{};
    for (final v in variants) {
      groups.putIfAbsent(v.group, () => []).add(v);
    }
    return groups;
  }

  /// 구조를 성격별로 묶은 것. 선택 목록에서 묶음 제목 아래에 놓이고, 기도 요청과 성경 인용은 같은 묶음이다.
  static List<(String, List<BlockType>)> get sections => const [
    ('열람', [board, video, schedule, gallery]),
    ('참여', [devotion, prayer]),
  ];

  static BlockType fromId(String? id) =>
      values.firstWhere((t) => t.id == id, orElse: () => board);

  /// 이 구조가 보여줄 수 있는 자료. 일정은 일정, 유튜브 링크는 설교영상,
  /// 말씀묵상은 말씀묵상, 게시판은 공지·사진첩.
  List<BlockSource> get sources => switch (this) {
    gallery => [BlockSource.fromKind(ContentKind.photo)],
    prayer => [BlockSource.prayers],
    schedule => [BlockSource.events],
    video => [BlockSource.fromKind(ContentKind.sermon)],
    devotion => [BlockSource.fromKind(ContentKind.devotion)],
    board => [
      BlockSource.fromKind(ContentKind.notice),
      BlockSource.fromKind(ContentKind.photo),
    ],
  };
}

/// 구조 안의 디자인 한 가지.
class BlockVariant {
  const BlockVariant(this.id, this.label, this.group);

  final String id;
  final String label;

  /// 디자인의 성격 (예: 게시판의 "글 + 그림" / "글만"). 디자인 고르기에서 세로 한 줄이 된다.
  final String group;

  /// 같은 성격 안에서 구분하는 짧은 이름: "사진+글 · 목록" → "목록".
  String get shortLabel {
    final i = label.lastIndexOf(' · ');
    return i < 0 ? label : label.substring(i + 3);
  }
}

/// 블록이 보여줄 자료: 콘텐츠 종류(공지·일정·…).
class BlockSource {
  const BlockSource._(this.id, this.label, this.kind);

  factory BlockSource.fromKind(ContentKind k) =>
      BlockSource._(k.collection, k.label, k);

  static final events = BlockSource.fromKind(ContentKind.event);

  /// 교인이 나누는 기도제목 (기도 요청 구조의 자료). 콘텐츠 종류가 아니다.
  static const prayers = BlockSource._('prayers', '기도 요청', null);

  final String id;
  final String label;

  /// 콘텐츠 종류.
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
    this.style = BlockStyle.simple,
    this.paletteId = BlockPalette.defaultId,
  });

  final String id;
  final BlockType type;

  /// 색이 달라지는 구조([hasColor])에서 고른 스타일과 팔레트 색.
  final BlockStyle style;
  final String paletteId;

  /// 스타일·팔레트를 고를 수 있는 구조인가: 이미지·영상이 중심인 구조는 제외한다.
  bool get hasColor => switch (type) {
    BlockType.devotion || BlockType.schedule => true,
    BlockType.board => const {'text', 'compact', 'table'}.contains(variant),
    _ => false,
  };

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
    BlockStyle? style,
    String? paletteId,
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
      style: style ?? this.style,
      paletteId: paletteId ?? this.paletteId,
    );
  }

  Json toMap() => {
    'id': id,
    'type': type.id,
    'variant': variant,
    'source': source.id,
    'title': title,
    'limit': limit,
    'style': style.id,
    'palette': paletteId,
  };

  factory BlockConfig.fromMap(Map<String, dynamic> m) {
    var type = BlockType.fromId(m['type'] as String?);
    var source = BlockSource.fromId(m['source'] as String?);
    var variant = m['variant'] as String?;
    // 예전 구성: 게시판·캐러셀로 보여주던 설교영상은 유튜브 링크로, 말씀묵상은 말씀묵상 구조로, 일정은 일정 구조로 옮긴다.
    // (예전의 "캐러셀" 구조는 게시판에 합쳐졌다: 'carousel' id는 게시판으로 읽힌다.)
    if (type == BlockType.board) {
      if (source.kind == ContentKind.sermon) {
        type = BlockType.video;
      } else if (source.kind == ContentKind.devotion) {
        type = BlockType.devotion;
        variant = 'card';
      } else if (source.kind == ContentKind.event) {
        type = BlockType.schedule;
        variant = 'agenda';
      }
    }
    if (!type.sources.any((s) => s.id == source.id)) {
      source = type.sources.first;
    }
    var style = BlockStyle.fromId(m['style'] as String?);
    var palette = m['palette'] as String? ?? BlockPalette.defaultId;
    // 스타일을 고르기 전에 저장된 구성: 예전에 색이 붙어 있던 디자인을 모양 + 스타일 + 팔레트로 옮긴다.
    if (m['style'] == null) {
      final legacy = _legacyLook(type, variant);
      if (legacy != null) {
        variant = legacy.variant;
        style = legacy.style;
        palette = legacy.palette;
      }
    }
    return BlockConfig(
      id: m['id'] as String? ?? '',
      type: type,
      variant: type.variants.any((v) => v.id == variant)
          ? variant!
          : type.variants.first.id,
      source: source,
      title: m['title'] as String? ?? '',
      limit: (m['limit'] as num?)?.toInt().clamp(1, 20) ?? 5,
      style: style,
      paletteId: BlockPalette.all.any((p) => p.id == palette)
          ? palette
          : BlockPalette.defaultId,
    );
  }

  static ({String variant, BlockStyle style, String palette})? _legacyLook(
    BlockType type,
    String? variant,
  ) {
    BlockStyle s(String id) => BlockStyle.fromId(id);
    return switch ((type, variant)) {
      (BlockType.schedule, 'calendar_mono') => (
        variant: 'calendar',
        style: s('simple'),
        palette: 'ink',
      ),
      (BlockType.schedule, 'calendar') => (
        variant: 'calendar',
        style: s('neon'),
        palette: 'violet',
      ),
      (BlockType.schedule, 'calendar_paper') => (
        variant: 'calendar',
        style: s('simple'),
        palette: 'indigo',
      ),
      (BlockType.schedule, 'calendar_sunset') => (
        variant: 'calendar',
        style: s('neon'),
        palette: 'coral',
      ),
      (BlockType.schedule, 'calendar_pastel') => (
        variant: 'calendar',
        style: s('pastel'),
        palette: 'rose',
      ),
      (BlockType.schedule, 'strip_neon') => (
        variant: 'strip',
        style: s('neon'),
        palette: 'violet',
      ),
      (BlockType.schedule, 'strip_pastel') => (
        variant: 'strip',
        style: s('pastel'),
        palette: 'rose',
      ),
      (BlockType.schedule, 'agenda_neon') => (
        variant: 'agenda',
        style: s('neon'),
        palette: 'violet',
      ),
      (BlockType.schedule, 'agenda_pastel') => (
        variant: 'agenda',
        style: s('pastel'),
        palette: 'rose',
      ),
      _ => null,
    };
  }
}

/// 페이지가 속한 그룹. 하단 탭의 "홈" · "기도" · "말씀"에 각각 대응한다.
/// - 홈: 교회 → 교인, 소식과 열람 위주 (공지 · 설교영상 · 일정 · 사진첩 …).
/// - 기도: 중보기도 (기도 요청 …).
/// - 말씀: 말씀 묵상 · 요약 등.
/// "내 활동"은 그룹이 아니라 기도 · 말씀 페이지 구성에 따라 자동으로 만들어진다 ([MyActivity]).
enum PageGroup {
  home('home', '홈', '홈 페이지 구성'),
  prayer('prayer', '기도', '기도 페이지 구성'),
  word('word', '말씀', '말씀 페이지 구성');

  const PageGroup(this.id, this.label, this.sectionTitle);

  final String id;
  final String label;

  /// 페이지 편집 목록의 구역 제목.
  final String sectionTitle;

  static PageGroup fromId(String? id) =>
      values.firstWhere((g) => g.id == id, orElse: () => home);

  /// 이 구조의 페이지를 새로 만들 때 기본으로 놓이는 그룹.
  static PageGroup defaultFor(BlockType type) => switch (type) {
    BlockType.prayer => prayer,
    BlockType.devotion => word,
    _ => home,
  };
}

/// "내 활동"에 모이는 내 글의 종류. 기도 · 말씀 페이지의 구조에 따라 자동으로 정해진다.
enum MyActivity {
  prayer('내 기도제목'),
  devotion('내 묵상');

  const MyActivity(this.label);

  final String label;

  /// 이 구조의 기도 · 말씀 페이지가 있으면 내 활동에 들어가는 종류. 해당 없으면 null.
  static MyActivity? of(BlockType type) => switch (type) {
    BlockType.prayer => prayer,
    BlockType.devotion => devotion,
    _ => null,
  };

  /// 기도 · 말씀 페이지들에서 만들어지는 내 활동 목록 (중복 없이, 페이지 순서대로).
  static List<MyActivity> from(Iterable<PageConfig> pages) => {
    for (final p in pages)
      if (p.group != PageGroup.home && p.layout != null) ?of(p.layout!.type),
  }.toList();
}

/// 교회 페이지 하나: 홈 · 기도 · 말씀 그룹 중 한 곳의 한 칸이자, 하나의 레이아웃(구조 + 디자인).
/// 한 페이지에는 레이아웃을 하나만 둘 수 있다. 아직 고르지 않았으면 [layout]이 null이다.
class PageConfig {
  const PageConfig({
    required this.id,
    required this.title,
    this.icon = 'home',
    this.group = PageGroup.home,
    this.layout,
  });

  final String id;
  final String title;

  /// 메뉴 아이콘 이름 (화면 쪽 `pageIcons`에 있는 이름).
  final String icon;

  /// 홈 · 기도 · 말씀 중 어느 그룹에 둘지.
  final PageGroup group;
  final BlockConfig? layout;

  PageConfig copyWith({
    String? title,
    String? icon,
    PageGroup? group,
    BlockConfig? layout,
  }) => PageConfig(
    id: id,
    title: title ?? this.title,
    icon: icon ?? this.icon,
    group: group ?? this.group,
    layout: layout ?? this.layout,
  );

  /// 저장된 페이지를 읽는다. 구조를 여러 개 쌓던 예전 방식(`blocks`)의 페이지는 더 쓰지 않으므로 null을 돌려준다.
  /// 구조가 하나뿐인 예전 페이지는 그 구조를 레이아웃으로 이어받는다.
  static PageConfig? fromDoc(DocumentSnapshot<Json> doc) {
    final d = doc.data() ?? const {};
    final legacy = d['blocks'] as List? ?? const [];
    if (legacy.length > 1) return null;
    final raw = d['layout'] ?? (legacy.isEmpty ? null : legacy.first);
    // 없어진 구조(기도제목 메신저 · 내 기도제목)로 저장된 칸은 건너뛴다.
    final ok =
        raw is Map<String, dynamic> &&
        raw['type'] != 'messenger' &&
        raw['type'] != 'my_prayers';
    return PageConfig(
      id: doc.id,
      title: d['title'] as String? ?? '',
      icon: d['icon'] as String? ?? 'home',
      group: PageGroup.fromId(d['group'] as String?),
      layout: ok ? BlockConfig.fromMap(raw) : null,
    );
  }

  /// 아직 한 번도 편집하지 않은 교회가 보는 기본 구성: 홈(공지) · 말씀(말씀 묵상) · 기도(기도 요청).
  static final defaults = [
    // 홈: 공지사항과 일정.
    const PageConfig(
      id: 'main',
      title: '공지사항',
      icon: 'home',
      layout: BlockConfig(
        id: 'main-notices',
        type: BlockType.board,
        variant: 'banner',
        source: BlockSource._('notices', '공지사항', ContentKind.notice),
        title: '공지사항',
      ),
    ),
    const PageConfig(
      id: 'schedule',
      title: '일정',
      icon: 'event',
      layout: BlockConfig(
        id: 'schedule-calendar',
        type: BlockType.schedule,
        variant: 'calendar',
        source: BlockSource._('events', '일정', ContentKind.event),
        title: '일정',
      ),
    ),
    // 말씀: 최근 말씀 묵상 세 개를 캐러셀로.
    const PageConfig(
      id: 'devotion',
      title: '말씀 묵상',
      icon: 'book',
      group: PageGroup.word,
      layout: BlockConfig(
        id: 'devotion-list',
        type: BlockType.devotion,
        variant: 'carousel',
        source: BlockSource._('devotions', '말씀묵상', ContentKind.devotion),
        title: '말씀묵상',
        limit: 3,
      ),
    ),
    // 기도: 최신 기도 요청 네 장이 둥둥 떠다닌다.
    const PageConfig(
      id: 'prayer',
      title: '기도 요청',
      icon: 'favorite',
      group: PageGroup.prayer,
      layout: BlockConfig(
        id: 'prayer-feed',
        type: BlockType.prayer,
        variant: 'float',
        source: BlockSource._('prayers', '기도 요청', null),
        title: '기도 요청',
        limit: 4,
      ),
    ),
  ];
}
