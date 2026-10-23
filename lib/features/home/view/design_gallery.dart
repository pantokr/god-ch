import 'package:flutter/material.dart';

import '../../../core/layout/app_dialog.dart';
import '../../../core/theme.dart';
import '../../../data/models/church_content.dart';
import '../../../data/models/member.dart';
import '../../../data/models/page_layout.dart';
import '../../../data/models/prayer.dart';
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
    BlockType.carousel: Icons.view_carousel_outlined,
    BlockType.board: Icons.dashboard_outlined,
    BlockType.schedule: Icons.event_outlined,
    BlockType.messenger: Icons.forum_outlined,
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

  /// 1단계: 어떤 구조를 쌓을지 고른다. 디자인은 다음 단계에서 그 구조 것만 보인다.
  Widget _typeStep(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('구조를 골라요', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text('고르면 그 구조의 디자인만 보여줘요.', style: TextStyle(color: palette.muted)),
        const SizedBox(height: 16),
        ColumnWrap(
          wide: 2,
          children: [
            for (final t in BlockType.values)
              InkWell(
                borderRadius: BorderRadius.circular(AppRadius.card),
                onTap: () => setState(() => _type = t),
                child: Ink(
                  padding: const EdgeInsets.all(16),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              t.description,
                              style: TextStyle(
                                color: palette.muted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: palette.muted),
                    ],
                  ),
                ),
              ),
          ],
        ),
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
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _type = null),
              ),
            Expanded(
              child: Text(
                '${type.label} 디자인을 골라요',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '아래는 실제 모습이에요. 마음에 드는 디자인을 누르면 선택돼요.',
          style: TextStyle(color: context.palette.muted),
        ),
        const SizedBox(height: 16),
        ColumnWrap(
          wide: 2,
          children: [
            for (final v in type.variants)
              _DesignCard(
                type: type,
                variant: v,
                selected: current?.type == type && current?.variant == v.id,
              ),
          ],
        ),
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
                        variant.label,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (selected)
                      Icon(Icons.check_circle, size: 18, color: palette.brand),
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
/// 눌러도 반응하지 않고, 폭 [_virtualWidth]로 그린 뒤 칸 폭에 맞춰 줄이며 [height]만큼만 보여준다.
class DesignThumbnail extends StatelessWidget {
  const DesignThumbnail({
    super.key,
    required this.type,
    required this.variant,
    this.height = 150,
  });

  final BlockType type;
  final String variant;
  final double height;

  static const _virtualWidth = 440.0;

  /// 견본에 쓰는 자료 종류: 캐러셀 카드와 사진 격자는 사진, 일정은 일정, 나머지는 공지.
  static ContentKind _kind() => ContentKind.notice;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final mq = MediaQuery.of(context);
    final kind = switch ((type, variant)) {
      (BlockType.schedule, _) => ContentKind.event,
      (BlockType.carousel, 'cards') => ContentKind.photo,
      (BlockType.board, 'grid') => ContentKind.photo,
      _ => _kind(),
    };
    final Widget body = type == BlockType.messenger
        ? _SampleMessenger(variant: variant)
        : BlockContentBody(
            block: BlockConfig(
              id: 'sample',
              type: type,
              variant: variant,
              source: BlockSource.fromKind(kind),
            ),
            items: _sampleContents(kind),
            onOpen: (_) {},
          );
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: ColoredBox(
        color: palette.bg,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: ExcludeSemantics(
            child: IgnorePointer(
              child: FittedBox(
                fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: _virtualWidth,
                  // 모바일 폭으로 그려서 실제 휴대폰 화면과 같은 배치를 보여준다.
                  child: MediaQuery(
                    data: mq.copyWith(
                      size: Size(_virtualWidth, mq.size.height),
                    ),
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
    );
  }
}

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
        body: '장소: 본당\n함께 모여 말씀을 나눠요.',
        date: kind == ContentKind.event
            ? day(days[i])
            : now.subtract(Duration(days: i * 2)),
      ),
  ];
}

const _sampleMe = Member(
  id: 'me',
  churchId: '',
  churchName: '',
  name: '',
  role: Role.member,
  status: MemberStatus.approved,
);

List<Prayer> _samplePrayers() => [
  Prayer(
    id: 's1',
    authorId: 'other',
    title: '가정을 위해 기도해 주세요',
    content: '이번 주 시험을 앞둔 아이를 위해 함께 기도해 주세요.',
    visibility: PrayerVisibility.public,
    deleted: false,
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  Prayer(
    id: 's2',
    authorId: 'me',
    title: '감사 제목',
    content: '건강을 회복하게 해 주셔서 감사합니다.',
    visibility: PrayerVisibility.public,
    deleted: false,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  Prayer(
    id: 's3',
    authorId: 'other',
    title: '새 직장을 위해',
    content: '면접을 앞두고 있어요. 평안을 구합니다.',
    visibility: PrayerVisibility.public,
    deleted: false,
    createdAt: DateTime.now(),
  ),
];

/// 메신저 구조의 견본. 실제 기도제목 카드는 응원 기록을 읽어 오므로, 견본은 같은 모양의 단순한 카드로 그린다.
class _SampleMessenger extends StatelessWidget {
  const _SampleMessenger({required this.variant});

  final String variant;

  @override
  Widget build(BuildContext context) {
    final prayers = _samplePrayers();
    if (variant == 'bubbles') {
      return Column(
        children: [
          for (final p in prayers) PrayerBubble(prayer: p, me: _sampleMe),
        ],
      );
    }
    final palette = context.palette;
    return Column(
      children: [
        for (final p in prayers)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.surface,
              border: Border.all(color: palette.border),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(p.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 16,
                      color: palette.accent,
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.volunteer_activism_outlined,
                      size: 16,
                      color: palette.brand,
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
