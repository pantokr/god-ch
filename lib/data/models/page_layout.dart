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
  devotion('devotion', '말씀 묵상', '예) 오늘의 말씀, 묵상 나눔', [
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

  /// 구조를 성격별로 묶은 것. 선택 목록에서 묶음 제목 아래에 놓이고, 기도 요청과 말씀 묵상은 같은 묶음이다.
  /// 구조 고르기에 나오는 구조들. 기도 요청 · 말씀 묵상은 페이지 한 장을 통째로 제공하는
  /// 템플릿으로만 만들므로 여기에는 없다.
  static List<(String, List<BlockType>)> get sections => const [
    ('열람', [board, video, schedule, gallery]),
  ];

  /// 페이지 한 장을 통째로 쓰는 구조(기도 요청 · 말씀 묵상). 홈에 이어 붙일 수 없다.
  bool get wholePage => this == prayer || this == devotion;

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

/// 유튜브 구조가 영상을 가져오는 방식.
enum VideoMode {
  manual('manual', '직접 게시'),
  channel('channel', '채널 최신 영상'),
  playlist('playlist', '재생목록 최신 영상');

  const VideoMode(this.id, this.label);

  final String id;
  final String label;

  /// 저장된 방식. 없으면(방식을 나누기 전 구성) 주소를 보고 정한다.
  static VideoMode fromId(String? id, String feedUrl) {
    for (final m in values) {
      if (m.id == id) return m;
    }
    if (feedUrl.trim().isEmpty) return manual;
    return youtubePlaylistTarget(feedUrl) != null ? playlist : channel;
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
    this.feedUrl = '',
    this.videoMode = VideoMode.manual,
    this.category = '',
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

  /// 새 템플릿(기도 요청 · 말씀 묵상) 블록: 기본 디자인과 개수로 시작한다.
  factory BlockConfig.template(BlockType type) {
    final source = type.sources.first;
    return BlockConfig(
      id: 'b${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      variant: type == BlockType.prayer ? 'float' : 'carousel',
      source: source,
      title: source.label,
      limit: type == BlockType.prayer ? 4 : 3,
    );
  }

  /// 고른 디자인의 id ([BlockType.variants] 중 하나).
  final String variant;
  final BlockSource source;

  /// 구역 제목. 비워 두면 제목 없이 보여준다.
  final String title;

  /// 보여줄 최대 개수.
  final int limit;

  /// 유튜브 구조에서 채널이나 재생목록 주소 ([videoMode]에 맞는 주소).
  final String feedUrl;

  /// 유튜브 구조가 영상을 가져오는 방식: 직접 게시 · 채널 최신 영상 · 재생목록 최신 영상.
  final VideoMode videoMode;

  /// 이 구조가 보여줄 글의 분류. 비우면 그 종류의 글 전체. 같은 종류의 구조를 여러 개 이어 붙여도
  /// 분류를 달리하면 서로 다른 글을 보여준다 ([supportsCategory]인 구조만).
  final String category;

  /// 글 분류로 보여줄 글을 고를 수 있는 구조인가: 게시판 · 갤러리 · 직접 게시하는 유튜브.
  bool get supportsCategory => switch (type) {
    BlockType.board || BlockType.gallery => true,
    BlockType.video => videoMode == VideoMode.manual,
    _ => false,
  };

  /// 분류 글자 수 제한 (`firestore.rules`와 같아야 한다).
  static const maxCategoryLength = ChurchContent.maxCategoryLength;

  /// 이 구조가 글 [c]를 보여주는가: 같은 종류이고, 영역을 정했다면 그 영역의 글이어야 한다.
  /// (채널 · 재생목록에서 가져오는 유튜브 구조는 교회 글을 보여주지 않는다.)
  bool shows(ChurchContent c) {
    if (source.kind != c.kind) return false;
    if (type == BlockType.video && usesFeed) return false;
    if (supportsCategory && category.isNotEmpty) return c.category == category;
    return true;
  }

  /// 유튜브 구조가 채널·재생목록의 새 영상을 자동으로 보여주는가 (방식에 맞는 주소일 때).
  bool get usesFeed =>
      type == BlockType.video &&
      switch (videoMode) {
        VideoMode.manual => false,
        VideoMode.channel => youtubeChannelTarget(feedUrl) != null,
        VideoMode.playlist => youtubePlaylistTarget(feedUrl) != null,
      };

  /// 유튜브 구조가 한 번에 보여줄 영상 수의 범위. 그보다 많으면 "더 보기"로 펼친다.
  static const videoLimits = (min: 1, max: 5);

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
    String? feedUrl,
    VideoMode? videoMode,
    String? category,
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
      feedUrl: feedUrl ?? this.feedUrl,
      videoMode: videoMode ?? this.videoMode,
      category: category ?? this.category,
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
    'feedUrl': feedUrl,
    'videoMode': videoMode.id,
    'category': category,
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
    final feed = m['feedUrl'] as String? ?? '';
    return BlockConfig(
      id: m['id'] as String? ?? '',
      type: type,
      variant: type.variants.any((v) => v.id == variant)
          ? variant!
          : type.variants.first.id,
      source: source,
      title: m['title'] as String? ?? '',
      limit:
          (m['limit'] as num?)?.toInt().clamp(
            1,
            type == BlockType.video ? videoLimits.max : 20,
          ) ??
          5,
      feedUrl: feed,
      videoMode: VideoMode.fromId(m['videoMode'] as String?, feed),
      category: m['category'] as String? ?? '',
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

/// 페이지가 놓이는 자리. 어떤 페이지든 어느 자리에든 놓을 수 있다 (템플릿 페이지는 홈만 빼고).
/// - 홈: 하단 가운데 버튼. 여러 개를 위에서 아래로 이어 붙인다.
/// - 왼쪽 버튼 · 오른쪽 버튼: 하단 탭 양옆 버튼. 각각 하나만 놓인다.
/// - 좌측 탭: 왼쪽 메뉴의 항목. 최대 [maxDrawer]개 (저장 값은 예전 이름 `drawer` 그대로).
/// "내 활동"은 자리가 아니라 기도 요청 · 말씀 묵상 템플릿 페이지에 따라 자동으로 만들어진다 ([MyActivity]).
enum PageGroup {
  home('home', '홈', '홈 (이어 붙이기)'),
  left('left', '왼쪽 버튼', '왼쪽 버튼 (1개)'),
  right('right', '오른쪽 버튼', '오른쪽 버튼 (1개)'),
  drawer('drawer', '좌측 탭', '좌측 탭 (최대 $maxDrawer개)');

  const PageGroup(this.id, this.label, this.sectionTitle);

  final String id;
  final String label;

  /// 페이지 편집 목록의 구역 제목.
  final String sectionTitle;

  /// 좌측 탭에 둘 수 있는 페이지 수. 늘리려면 이 값만 바꾼다.
  static const maxDrawer = 4;

  /// 한 자리에 페이지 하나만 놓인다 (하단 탭 양옆).
  bool get single => this == left || this == right;

  /// 이 자리에 놓을 수 있는 최대 페이지 수. null이면 제한이 없다.
  int? get capacity => single ? 1 : (this == drawer ? maxDrawer : null);

  /// 예전에 쓰던 자리 이름(기도 · 말씀)은 왼쪽 · 오른쪽 버튼으로 이어받는다.
  static PageGroup fromId(String? id) => switch (id) {
    'prayer' => left,
    'word' => right,
    _ => values.firstWhere((g) => g.id == id, orElse: () => home),
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

  /// 기도 요청 · 말씀 묵상 템플릿 페이지들에서 만들어지는 내 활동 목록 (중복 없이, 페이지 순서대로).
  static List<MyActivity> from(Iterable<PageConfig> pages) => {
    for (final p in pages)
      for (final b in p.blocks) ?of(b.type),
  }.toList();
}

/// 교회 페이지 하나: 홈 · 왼쪽 버튼 · 오른쪽 버튼 · 좌측 탭 중 한 곳의 한 칸.
/// 먼저 페이지를 만들고, 그 안에 템플릿 1개(기도 요청 · 말씀 묵상) 또는 구조(게시판 · 일정 …) 여러 개를
/// 위에서 아래로 이어 붙인다. 템플릿이 있는 페이지에는 구조를 더할 수 없고,
/// 같은 템플릿은 교회에 하나만 둘 수 있다 (운영 설정이 교회 단위라서).
class PageConfig {
  const PageConfig({
    required this.id,
    required this.title,
    this.icon = 'home',
    this.group = PageGroup.home,
    this.blocks = const [],
    this.updatedAt,
  });

  final String id;
  final String title;

  /// 메뉴 아이콘 이름 (화면 쪽 `pageIcons`에 있는 이름).
  final String icon;

  /// 홈 · 왼쪽 버튼 · 오른쪽 버튼 · 좌측 탭 중 어느 자리에 둘지.
  final PageGroup group;

  /// 페이지에 이어 붙인 템플릿 하나, 또는 구조들. 비어 있으면 아직 구성이 없는 페이지.
  final List<BlockConfig> blocks;

  /// 마지막으로 저장된 시각. 동시에 고치는 것을 막는 데 쓴다 (저장된 적 없으면 null).
  final DateTime? updatedAt;

  /// 한 페이지에 둘 수 있는 구조의 최대 개수.
  static const maxStructures = 8;

  /// 페이지를 통째로 쓰는 템플릿 (기도 요청 · 말씀 묵상). 없으면 null.
  BlockConfig? get template =>
      blocks.where((b) => b.type.wholePage).firstOrNull;

  bool get hasTemplate => template != null;

  /// 템플릿 페이지는 홈에 둘 수 없다.
  bool canBeIn(PageGroup g) => !(g == PageGroup.home && hasTemplate);

  /// [pages] 중 글 [c]가 보이는 페이지들 (콘텐츠 관리에서 "어디에 속해 있는지" 알려 줄 때 쓴다).
  static List<PageConfig> showing(
    Iterable<PageConfig> pages,
    ChurchContent c,
  ) => [
    for (final p in pages)
      if (p.blocks.any((b) => b.shows(c))) p,
  ];

  /// [pages]를 마지막으로 저장한 시각 중 가장 늦은 것. 이 화면을 연 뒤 누가 먼저 저장했는지 알아내는 기준이다.
  static DateTime? versionOf(Iterable<PageConfig> pages) {
    DateTime? v;
    for (final p in pages) {
      final t = p.updatedAt;
      if (t != null && (v == null || t.isAfter(v))) v = t;
    }
    return v;
  }

  /// [pages]에서 [pageId]를 [to] 자리에 두도록 바꾼 목록 (순서는 그대로).
  /// 한 칸짜리 자리(왼쪽 · 오른쪽 버튼)에 있던 다른 페이지는 홈으로(홈에 둘 수 없으면 좌측 탭으로) 옮겨진다.
  /// 둘 수 없으면(좌측 탭이 꽉 참, 템플릿 페이지를 홈으로) null.
  static List<PageConfig>? place(
    List<PageConfig> pages,
    String pageId,
    PageGroup to,
  ) {
    final page = pages.firstWhere((p) => p.id == pageId);
    if (!page.canBeIn(to)) return null;
    final cap = to.capacity;
    final others = pages.where((p) => p.id != pageId && p.group == to).length;
    if (cap != null && !to.single && others >= cap) return null;
    var drawer = pages.where((p) => p.group == PageGroup.drawer).length;
    final out = <PageConfig>[];
    for (final p in pages) {
      if (p.id == pageId) {
        out.add(p.copyWith(group: to));
      } else if (to.single && p.group == to) {
        if (p.canBeIn(PageGroup.home)) {
          out.add(p.copyWith(group: PageGroup.home));
        } else if (drawer < PageGroup.maxDrawer) {
          drawer++;
          out.add(p.copyWith(group: PageGroup.drawer));
        } else {
          return null;
        }
      } else {
        out.add(p);
      }
    }
    return out;
  }

  /// 자리 · 구성 제한을 어긴 곳이 있으면 그 안내 문구, 없으면 null.
  static String? slotError(Iterable<PageConfig> pages) {
    for (final p in pages) {
      if (!p.canBeIn(p.group)) return '"${p.title}"은(는) 홈에 둘 수 없어요.';
      if (p.hasTemplate && p.blocks.length > 1) {
        return '"${p.title}"은(는) 템플릿이 있어 구조를 더할 수 없어요.';
      }
      if (p.blocks.length > maxStructures) {
        return '"${p.title}"에는 구조를 $maxStructures개까지 둘 수 있어요.';
      }
    }
    for (final t in BlockType.values.where((t) => t.wholePage)) {
      final count = pages.where((p) => p.template?.type == t).length;
      if (count > 1) return '${t.label} 템플릿은 교회에 하나만 둘 수 있어요.';
    }
    for (final g in PageGroup.values) {
      final cap = g.capacity;
      if (cap != null && pages.where((p) => p.group == g).length > cap) {
        return '${g.label}에는 $cap개까지 둘 수 있어요.';
      }
    }
    return null;
  }

  PageConfig copyWith({
    String? title,
    String? icon,
    PageGroup? group,
    List<BlockConfig>? blocks,
  }) => PageConfig(
    id: id,
    title: title ?? this.title,
    icon: icon ?? this.icon,
    group: group ?? this.group,
    blocks: blocks ?? this.blocks,
    updatedAt: updatedAt,
  );

  /// 저장된 페이지를 읽는다.
  static PageConfig? fromDoc(DocumentSnapshot<Json> doc) =>
      fromData(doc.id, doc.data() ?? const {});

  /// 저장된 값에서 페이지를 만든다. 구조 목록(`structures`)이 기본이고, 예전의 단일 `layout`과
  /// 구조가 하나뿐인 `blocks`도 이어받는다. 여러 개를 쌓던 예전 `blocks`는 더 쓰지 않으므로 null을 돌려준다.
  static PageConfig? fromData(String id, Map<String, dynamic> d) {
    final legacy = d['blocks'] as List? ?? const [];
    if (legacy.length > 1 && d['structures'] == null) return null;
    final raw =
        d['structures'] as List? ??
        [
          if (d['layout'] != null)
            d['layout']
          else if (legacy.isNotEmpty)
            legacy.first,
        ];
    return PageConfig(
      id: id,
      title: d['title'] as String? ?? '',
      icon: d['icon'] as String? ?? 'home',
      group: PageGroup.fromId(d['group'] as String?),
      // 없어진 구조(기도제목 메신저 · 내 기도제목)로 저장된 칸은 건너뛴다.
      blocks: [
        for (final r in raw)
          if (r is Map<String, dynamic> &&
              r['type'] != 'messenger' &&
              r['type'] != 'my_prayers')
            BlockConfig.fromMap(r),
      ],
      updatedAt: toDate(d['updatedAt']),
    );
  }

  /// 아직 한 번도 편집하지 않은 교회가 보는 기본 구성: 홈(공지 · 일정) · 왼쪽 버튼(기도 요청) · 오른쪽 버튼(말씀 묵상).
  static final defaults = [
    // 홈: 공지사항과 일정.
    const PageConfig(
      id: 'main',
      title: '공지사항',
      icon: 'home',
      blocks: [
        BlockConfig(
          id: 'main-notices',
          type: BlockType.board,
          variant: 'banner',
          source: BlockSource._('notices', '공지사항', ContentKind.notice),
          title: '공지사항',
        ),
      ],
    ),
    const PageConfig(
      id: 'schedule',
      title: '일정',
      icon: 'event',
      blocks: [
        BlockConfig(
          id: 'schedule-calendar',
          type: BlockType.schedule,
          variant: 'calendar',
          source: BlockSource._('events', '일정', ContentKind.event),
          title: '일정',
        ),
      ],
    ),
    // 말씀 묵상 템플릿: 최근 말씀 묵상 세 개를 캐러셀로.
    const PageConfig(
      id: 'devotion',
      title: '말씀 묵상',
      icon: 'book',
      group: PageGroup.right,
      blocks: [
        BlockConfig(
          id: 'devotion-list',
          type: BlockType.devotion,
          variant: 'carousel',
          source: BlockSource._('devotions', '말씀묵상', ContentKind.devotion),
          title: '말씀묵상',
          limit: 3,
        ),
      ],
    ),
    // 기도 요청 템플릿: 최신 기도 요청 네 장이 둥둥 떠다닌다.
    const PageConfig(
      id: 'prayer',
      title: '기도 요청',
      icon: 'favorite',
      group: PageGroup.left,
      blocks: [
        BlockConfig(
          id: 'prayer-feed',
          type: BlockType.prayer,
          variant: 'float',
          source: BlockSource._('prayers', '기도 요청', null),
          title: '기도 요청',
          limit: 4,
        ),
      ],
    ),
  ];

  /// 처음 시작하거나 되돌릴 때 고르는 시작 구성들.
  static final presets = [
    PagePreset('기본 구성', '공지 · 일정 · 기도 · 말씀', defaults),
    PagePreset('소규모 교회', '공지 하나로 간단하게', [
      PageConfig(
        id: 'main',
        title: '공지사항',
        icon: 'home',
        blocks: [
          BlockConfig(
            id: 'main-notices',
            type: BlockType.board,
            variant: 'list',
            source: BlockType.board.sources.first,
            title: '공지사항',
          ),
        ],
      ),
      defaults[2],
      defaults[3],
    ]),
    PagePreset('청년부 중심', '소식 · 영상 · 갤러리 · 기도 · 말씀', [
      PageConfig(
        id: 'news',
        title: '소식',
        icon: 'campaign',
        blocks: [
          BlockConfig(
            id: 'news-board',
            type: BlockType.board,
            variant: 'banner',
            source: BlockType.board.sources.first,
            title: '공지사항',
          ),
          BlockConfig(
            id: 'news-schedule',
            type: BlockType.schedule,
            variant: 'strip',
            source: BlockType.schedule.sources.first,
            title: '일정',
          ),
          BlockConfig(
            id: 'news-video',
            type: BlockType.video,
            variant: 'cards',
            source: BlockType.video.sources.first,
            title: '영상',
            limit: 3,
          ),
        ],
      ),
      defaults[2],
      defaults[3],
      PageConfig(
        id: 'album',
        title: '갤러리',
        icon: 'photo',
        group: PageGroup.drawer,
        blocks: [
          BlockConfig(
            id: 'album-gallery',
            type: BlockType.gallery,
            variant: 'albums',
            source: BlockType.gallery.sources.first,
            title: '사진첩',
          ),
        ],
      ),
    ]),
  ];
}

/// 시작 구성 하나: 이름, 한 줄 설명, 페이지들.
class PagePreset {
  const PagePreset(this.label, this.summary, this.pages);

  final String label;
  final String summary;
  final List<PageConfig> pages;
}

/// 페이지 구성을 저장하기 직전의 모습. 저장할 때마다 하나씩 남기고, 이전 구성으로 되돌릴 때 쓴다.
class PageRevision {
  const PageRevision({
    required this.id,
    required this.savedAt,
    required this.pages,
  });

  final String id;

  /// 이 구성이 바뀐(다음 구성이 저장된) 시각.
  final DateTime? savedAt;
  final List<PageConfig> pages;

  factory PageRevision.fromDoc(DocumentSnapshot<Json> doc) {
    final d = doc.data() ?? const {};
    final raw =
        [
          for (final r in d['pages'] as List? ?? const [])
            if (r is Map<String, dynamic>) r,
        ]..sort(
          (a, b) =>
              ((a['order'] as num?) ?? 0).compareTo((b['order'] as num?) ?? 0),
        );
    return PageRevision(
      id: doc.id,
      savedAt: toDate(d['savedAt']),
      pages: [
        for (final r in raw) ?PageConfig.fromData(r['id'] as String? ?? '', r),
      ],
    );
  }
}
