import '../../../core/icons.dart';

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';

import '../../../core/layout/app_dialog.dart';
import '../../../core/theme.dart';
import '../../../data/models/block_style.dart';
import '../../../data/models/church_content.dart';
import '../../../data/models/page_layout.dart';
import 'block_views.dart';
import 'content_widgets.dart';

/// 갤러리에서 고른 구조와 디자인.
class DesignChoice {
  const DesignChoice(this.type, this.variant);

  final BlockType type;
  final String variant;
}

/// 디자인 고르기. 먼저 구조(캐러셀·게시판 …)를 고르고, 그 구조의 디자인만 실제 모습으로 늘어놓아 하나를 고른다.
/// [only]를 주면(이미 쓰는 구조의 디자인을 바꿀 때) 구조 고르기를 건너뛰고 그 구조의 디자인만 보여준다.
/// 현재 쓰는 디자인에는 표시가 붙는다.
Future<DesignChoice?> showDesignGallery(
  BuildContext context, {
  BlockType? only,
  DesignChoice? current,
}) => showAppDialog<DesignChoice>(
  context,
  maxWidth: 760,
  child: _Gallery(only: only, current: current),
);

class _Gallery extends StatefulWidget {
  const _Gallery({this.only, this.current});

  final BlockType? only;
  final DesignChoice? current;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  /// 고른 구조. null이면 구조 고르기 단계.
  late BlockType? _type = widget.only;

  static const _typeIcons = {
    BlockType.video: AppIcons.monitorPlay,
    BlockType.devotion: AppIcons.bookOpen,
    BlockType.board: AppIcons.squaresFour,
    BlockType.schedule: AppIcons.calendarBlank,
    BlockType.gallery: AppIcons.images,
    BlockType.prayer: AppIcons.heart,
  };

  @override
  Widget build(BuildContext context) {
    final type = _type;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (type == null) _typeStep(context) else _variantStep(context, type),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ),
      ],
    );
  }

  /// 1단계: 어떤 구조를 쓸지 고른다. 디자인은 다음 단계에서 그 구조 것만 보인다.
  Widget _typeStep(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('구조 선택', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        // 성격별로 묶어 늘어놓는다 (열람 / 참여).
        for (final (title, types) in BlockType.sections) ...[
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Text(
              title,
              style: TextStyle(
                color: palette.muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ColumnWrap(
            wide: 2,
            children: [
              for (final t in types)
                InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  onTap: () => setState(() => _type = t),
                  child: Ink(
                    // 모든 구조 카드가 같은 크기가 되도록 높이를 고정한다.
                    height: 76,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      border: Border.all(color: palette.border),
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: Row(
                      children: [
                        Icon(_typeIcons[t], color: palette.brand),
                        const SizedBox(width: 12),
                        Expanded(
                          // 글자는 카드 안에서 상하 중앙에 놓는다.
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(AppIcons.caretRight, color: palette.muted),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  /// 2단계: 고른 구조의 디자인만 실제 모습으로 늘어놓는다.
  Widget _variantStep(BuildContext context, BlockType type) {
    final current = widget.current;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            // 구조를 고르는 길이면 구조 고르기로 돌아갈 수 있다.
            if (widget.only == null)
              IconButton(
                tooltip: '구조 다시 고르기',
                icon: const Icon(AppIcons.arrowLeft),
                onPressed: () => setState(() => _type = null),
              ),
            Expanded(
              child: Text(
                '디자인 선택',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 세로(y)는 디자인의 성격, 가로(x)는 그 성격 안의 디자인들. 줄마다 옆으로 밀어 볼 수 있다.
        for (final entry in type.variantGroups.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Row(
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${entry.value.length}가지',
                  style: TextStyle(color: context.palette.muted, fontSize: 12),
                ),
                const SizedBox(width: 12),
                Expanded(child: Divider(color: context.palette.border)),
              ],
            ),
          ),
          _DesignRow(
            children: [
              for (final v in entry.value)
                SizedBox(
                  width: 280,
                  child: _DesignCard(
                    type: type,
                    variant: v,
                    selected: current?.type == type && current?.variant == v.id,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _DesignCard extends StatelessWidget {
  const _DesignCard({
    required this.type,
    required this.variant,
    required this.selected,
  });

  final BlockType type;
  final BlockVariant variant;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final radius = BorderRadius.circular(AppRadius.card);
    return Material(
      color: palette.surface,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: () => Navigator.pop(context, DesignChoice(type, variant.id)),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: selected ? palette.brand : palette.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: DesignThumbnail(type: type, variant: variant.id),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        variant.shortLabel,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (selected)
                      Icon(
                        AppIcons.checkCircleFill,
                        size: 18,
                        color: palette.brand,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 디자인의 실제 모습을 줄여서 보여주는 견본. 실제 페이지와 같은 위젯을 견본 자료로 그린다.
/// 눌러도 반응하지 않고, 폭 [_virtualWidth]로 그린 뒤 칸 폭에 맞춰 줄이며, 칸은 항상 4:3 비율이다.
class DesignThumbnail extends StatelessWidget {
  const DesignThumbnail({
    super.key,
    required this.type,
    required this.variant,
    this.style = BlockStyle.simple,
    this.paletteId = BlockPalette.defaultId,
  });

  final BlockType type;
  final String variant;

  /// 색이 달라지는 구조의 견본에 적용할 스타일과 팔레트.
  final BlockStyle style;
  final String paletteId;

  static const _virtualWidth = 440.0;

  /// 사진을 쓰는 게시판 디자인(견본 자료가 사진첩이다).
  static const _photoVariants = {'tiles', 'cards', 'feature'};

  /// 줄이 짧아 견본에 자료를 다 보여줘도 칸을 넘지 않는 게시판 디자인.
  static const _wideSamples = {'banner', 'cards'};

  /// 카드 슬라이드는 카드 한 장(220px)이 칸에 크게 보이도록 더 좁은 폭으로 그린다.
  double get _width =>
      type == BlockType.board && variant == 'cards' ? 300.0 : _virtualWidth;

  /// 견본에 쓰는 자료 종류: 캐러셀 카드와 사진 격자는 사진, 일정은 일정, 나머지는 공지.
  static ContentKind _kind() => ContentKind.notice;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final mq = MediaQuery.of(context);
    final kind = switch ((type, variant)) {
      (BlockType.schedule, _) => ContentKind.event,
      (BlockType.board, _) when _photoVariants.contains(variant) =>
        ContentKind.photo,
      (BlockType.video, _) => ContentKind.sermon,
      (BlockType.gallery, _) => ContentKind.photo,
      (BlockType.devotion, _) => ContentKind.devotion,
      _ => _kind(),
    };
    final Widget body = type == BlockType.prayer
        ? const _SamplePrayers()
        : BlockContentBody(
            block: BlockConfig(
              id: 'sample',
              type: type,
              variant: variant,
              source: BlockSource.fromKind(kind),
              style: style,
              paletteId: paletteId,
            ),
            // 목록·간단히는 줄이 길어 견본 높이를 넘으므로 두 줄만 보여 잘려 보이지 않게 한다.
            items:
                (type == BlockType.board && !_wideSamples.contains(variant)) ||
                    type == BlockType.devotion
                ? _sampleContents(kind)
                      .take(
                        type == BlockType.devotion
                            ? (variant == 'carousel' ? 3 : 1)
                            : 2,
                      )
                      .toList()
                : _sampleContents(kind),
            onOpen: (_) {},
          );
    // 바깥과 확실히 구분되도록 뚜렷한 테두리로 감싼다.
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: palette.muted, width: 1.5),
        borderRadius: BorderRadius.circular(AppRadius.control + 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: ColoredBox(
          color: palette.bg,
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: ExcludeSemantics(
              child: IgnorePointer(
                child: FittedBox(
                  // 4:3 칸 안에 내용 전체가 비율 그대로 들어가고, 칸이 커지면 내용도 함께 커진다.
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: _width,
                    // 모바일 폭으로 그려서 실제 휴대폰 화면과 같은 배치를 보여준다.
                    child: MediaQuery(
                      data: mq.copyWith(size: Size(_width, mq.size.height)),
                      // Ink 배경은 가장 가까운 Material에 그려지므로, 견본 안에 따로 둬서
                      // 줄이고 잘라낸 견본 밖으로 새어 나오지 않게 한다.
                      child: Material(
                        type: MaterialType.transparency,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: body,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 말씀묵상 견본의 구절 본문 (견본 제목의 순서와 맞춘다).
const devotionVerses = [
  '여호와는 나의 목자시니 내가 부족함이 없으리로다. 그가 나를 푸른 풀밭에 누이시며 쉴 만한 물가로 인도하시는도다.',
  '아무 것도 염려하지 말고 다만 모든 일에 기도와 간구로, 너희 구할 것을 감사함으로 하나님께 아뢰라.',
];

List<ChurchContent> _sampleContents(ContentKind kind) {
  final now = DateTime.now();
  DateTime day(int d) {
    final last = DateTime(now.year, now.month + 1, 0).day;
    return DateTime(now.year, now.month, d > last ? last : d, 10);
  }

  const titles = {
    ContentKind.notice: ['이번 주일 예배 안내', '가을 특별새벽기도회', '교회학교 교사 모집'],
    ContentKind.event: ['청년부 모임', '구역 예배', '교회학교 소풍', '감사 예배'],
    ContentKind.photo: ['가을 야외 예배', '여름성경학교', '새가족 환영회'],
    ContentKind.sermon: ['선한 목자', '씨 뿌리는 자'],
    ContentKind.devotion: ['시편 23:1', '빌립보서 4:6-7'],
  };
  final days = [3, 12, 12, 24];
  final names = titles[kind]!;
  return [
    for (var i = 0; i < names.length; i++)
      ChurchContent(
        id: 'sample$i',
        kind: kind,
        title: names[i],
        body: kind == ContentKind.devotion
            ? devotionVerses[i % devotionVerses.length]
            : '장소: 본당\n함께 모여 말씀을 나눠요.',
        date: kind == ContentKind.event
            ? day(days[i])
            : now.subtract(Duration(days: i * 2)),
        // 사진·영상(·공지) 견본은 이미지 아이콘 대신 대체 이미지를 보여준다.
        imageUrls: switch (kind) {
          // 사진 견본은 여러 장이라 겹겹이 쌓인 모양도 보인다.
          ContentKind.photo => [
            for (var j = 0; j < 3; j++)
              kSampleImages[(i + j) % kSampleImages.length],
          ],
          ContentKind.sermon ||
          ContentKind.notice => [kSampleImages[i % kSampleImages.length]],
          _ => const [],
        },
      ),
  ];
}

/// 같은 성격의 디자인을 가로로 늘어놓은 줄. 마우스로도 밀 수 있고(끌기), 양끝의 화살표로도 넘길 수 있다.
class _DesignRow extends StatefulWidget {
  const _DesignRow({required this.children});

  final List<Widget> children;

  @override
  State<_DesignRow> createState() => _DesignRowState();
}

class _DesignRowState extends State<_DesignRow> {
  final _controller = ScrollController();
  bool _canBack = false;
  bool _canForward = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_update);
    // 처음 그려진 뒤에 넘길 곳이 있는지 확인한다.
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _update() {
    if (!_controller.hasClients || !mounted) return;
    final p = _controller.position;
    final back = p.pixels > 1;
    final forward = p.pixels < p.maxScrollExtent - 1;
    if (back != _canBack || forward != _canForward) {
      setState(() {
        _canBack = back;
        _canForward = forward;
      });
    }
  }

  void _page(int direction) {
    final p = _controller.position;
    _controller.animateTo(
      (p.pixels + direction * (p.viewportDimension * 0.8)).clamp(
        0.0,
        p.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  Widget _arrow(bool left) => Positioned(
    left: left ? 0 : null,
    right: left ? null : 0,
    top: 0,
    bottom: 0,
    child: Center(
      child: Material(
        color: context.palette.surface,
        elevation: 4,
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: left ? '이전 디자인' : '다음 디자인',
          icon: Icon(left ? AppIcons.caretLeft : AppIcons.caretRight),
          onPressed: () => _page(left ? -1 : 1),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _update());
        return false;
      },
      child: Stack(
        children: [
          // 데스크탑에서는 마우스 끌기로는 기본적으로 밀리지 않으므로 모든 입력 장치를 허용한다.
          ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: PointerDeviceKind.values.toSet(),
              scrollbars: false,
            ),
            child: SingleChildScrollView(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              // 선택 표시의 굵은 테두리와 그림자가 잘리지 않도록 위아래에 여백을 둔다.
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final c in widget.children)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: c,
                    ),
                ],
              ),
            ),
          ),
          if (_canBack) _arrow(true),
          if (_canForward) _arrow(false),
        ],
      ),
    );
  }
}

/// 기도 요청 디자인의 견본: 기도제목 카드 두 장.
class _SamplePrayers extends StatelessWidget {
  const _SamplePrayers();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    Widget card(String title, String body) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(body, style: TextStyle(color: palette.muted, fontSize: 13)),
          const SizedBox(height: 8),
          const Text('🙏 3   💗 5   📣 1'),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          card('가족을 위해', '건강하게 지낼 수 있도록 기도해 주세요.'),
          const SizedBox(height: 8),
          card('시험을 앞두고', '마음의 평안을 구합니다.'),
        ],
      ),
    );
  }
}
