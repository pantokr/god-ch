import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../data/models/block_style.dart';
import '../../../data/models/church_content.dart';
import '../../../data/models/department.dart';
import '../../../data/models/member.dart';
import '../../../data/models/page_layout.dart';
import '../../../data/models/prayer_settings.dart';
import '../view_model/block_view_model.dart';
import '../../prayers/view/floating_prayers.dart';
import '../../prayers/view/prayer_list.dart';
import 'board_tiles.dart';
import 'content_tiles.dart';
import 'devotion_carousel.dart';
import 'devotion_designs.dart';
import 'agenda_designs.dart';
import 'content_widgets.dart';
import 'gallery_page.dart' show AlbumCard, StackedAlbumCard;
import 'month_calendar.dart';
import 'block_theme.dart';
import 'notice_carousel.dart';

/// 페이지의 구조(블록) 하나를 고른 디자인으로 그린다.
/// 구조: 캐러셀 · 게시판 · 일정 · 메신저. 구조마다 여러 디자인이 있고 교역자가 고른다.
class BlockView extends StatelessWidget {
  const BlockView({
    super.key,
    required this.block,
    required this.me,
    this.department,
    this.inset = 0,
    this.fullScreen = false,
  });

  final BlockConfig block;
  final Member me;
  final Department? department;

  /// 제목도 카드도 없이 화면 전체를 쓴다 (기도 · 말씀 탭).
  final bool fullScreen;

  /// 구조를 놓는 칸의 좌우 안쪽 여백. 카드 슬라이드는 이 여백에서 시작해 화면 끝까지 이어진다.
  final double inset;

  /// 옆으로 미는 카드 줄: 칸 바깥(화면 끝)까지 스크롤 영역을 넓힌다.
  bool get _bleeds => block.type == BlockType.board && block.variant == 'cards';

  @override
  Widget build(BuildContext context) {
    final kind = block.source.kind;
    return ViewModelBuilder<BlockViewModel>(
      // 자료가 바뀌는 설정(구조·종류·개수·부서)이 달라지면 스트림을 새로 만든다.
      key: ValueKey(
        '${block.id}/${block.type.id}/${block.source.id}/${block.limit}/${department?.id}',
      ),
      create: (context) {
        final scope = AppScope.read(context);
        return BlockViewModel(
          scope.contents,
          scope.prayers,
          me.churchId,
          block,
          departmentId: department?.id,
        );
      },
      builder: (context, vm) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: inset),
            child: fullScreen
                ? const SizedBox.shrink()
                : block.title.trim().isNotEmpty
                ? SectionHeader(
                    title: block.title.trim(),
                    onMore: kind == null || block.type == BlockType.schedule
                        ? null
                        : () => context.push(
                            Routes.contentList(me.churchId, kind),
                          ),
                  )
                : const SizedBox(height: 24),
          ),
          if (_bleeds)
            _body(context, vm)
          else
            Padding(
              padding: EdgeInsets.symmetric(horizontal: inset),
              child: _body(context, vm),
            ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, BlockViewModel vm) {
    if (block.type == BlockType.prayer) return _prayers(context, vm);
    if (block.type == BlockType.devotion && me.isStaff) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FilledButton.icon(
                onPressed: () => context.push(
                  Routes.contentEdit(me.churchId, kind: ContentKind.devotion),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('말씀 묵상 추가'),
              ),
            ),
          ),
          _contentBody(context, vm),
        ],
      );
    }
    return _contentBody(context, vm);
  }

  Widget _contentBody(BuildContext context, BlockViewModel vm) {
    final hint = me.isStaff ? '\n"콘텐츠 관리"에서 추가할 수 있어요.' : '';
    void open(ChurchContent c) =>
        context.push(Routes.contentDetail(me.churchId, c.kind, c.id));

    // 자료가 없거나 불러오는 중에도, 자료가 들어왔을 때와 같은 높이(이미지 4:3 기준)를 잡는다.
    return LayoutBuilder(
      builder: (context, box) {
        // 일반 구조는 이미 좌우 여백 안쪽에 놓여 있어 폭이 곧 칸 폭이다. 카드 줄만 화면 끝까지 이어지므로 여백을 뺀다.
        final contentWidth = _bleeds ? box.maxWidth - inset * 2 : box.maxWidth;
        final reserved = _reservedHeight(context, contentWidth);
        return ContentStream(
          stream: vm.content!,
          loadingHeight: reserved ?? 120,
          builder: (context, items) {
            if (items.isEmpty) {
              final empty = EmptyHint(
                block.type == BlockType.schedule
                    ? '이번 달 일정이 없어요.$hint'
                    : '등록된 ${block.source.label}이(가) 없어요.$hint',
                height: reserved,
              );
              return _bleeds
                  ? Padding(
                      padding: EdgeInsets.symmetric(horizontal: inset),
                      child: empty,
                    )
                  : empty;
            }
            return BlockContentBody(
              block: block,
              items: items,
              onOpen: open,
              hint: hint,
              me: me,
              bleedInset: inset,
            );
          },
        );
      },
    );
  }

  /// 기도 요청: 기도제목 쓰기 버튼과 공개 기도제목 카드들.
  Widget _prayers(BuildContext context, BlockViewModel vm) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      StreamBuilder<PrayerSettings>(
        stream: vm.prayerSettings,
        initialData: PrayerSettings.standard,
        builder: (context, cfg) {
          // 교회가 교역자만 쓰게 정했으면 교인에게는 쓰기 버튼이 보이지 않는다.
          final canWrite =
              (cfg.data ?? PrayerSettings.standard).writers ==
                  PrayerWriters.member ||
              me.isStaff;
          if (!canWrite) return const SizedBox.shrink();
          return Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FilledButton.icon(
                onPressed: () => context.push(
                  Routes.newPrayer(me.churchId, dept: department?.id),
                ),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('기도 요청'),
              ),
            ),
          );
        },
      ),
      if (block.variant == 'float')
        FloatingPrayers(
          prayers: vm.prayers!,
          me: me,
          count: block.limit.clamp(1, 4),
        )
      else
        PrayerGrid(
          prayers: vm.prayers!,
          me: me,
          emptyText: '기도제목 없음',
          showReactions: true,
          flat: fullScreen,
        ),
    ],
  );

  /// 이 구조가 이미지 한 줄(또는 한 장)을 그릴 때의 높이. 이미지 칸이 없는 구조는 null.
  double? _reservedHeight(BuildContext context, double width) {
    if (block.type != BlockType.board) return null;
    // ColumnWrap(narrow: 2, wide: 3)의 한 줄 높이.
    double gridRow() {
      final cols = width < 560 ? 2 : 3;
      final tile = (width - 12 * (cols - 1)) / cols;
      return tile / kThumbnailAspect;
    }

    return switch (block.variant) {
      'banner' => width / NoticeCarousel.aspectOf(context),
      'cards' => BlockContentBody.cardWidth / kThumbnailAspect,
      'feature' => width * 9 / 16,
      'tiles' => gridRow(),
      'list' when block.source.kind == ContentKind.photo => gridRow(),
      _ => null,
    };
  }
}

/// 콘텐츠를 보여주는 구조(캐러셀 · 게시판 · 일정)를 자료 [items]로 그린다.
/// 실제 페이지와 디자인 고르기의 견본이 같은 코드를 쓰므로, 견본이 곧 실제 모습이다.
class BlockContentBody extends StatelessWidget {
  const BlockContentBody({
    super.key,
    required this.block,
    required this.items,
    required this.onOpen,
    this.hint = '',
    this.me,
    this.bleedInset = 0,
  });

  /// 카드 슬라이드 줄의 앞뒤 여백. 줄은 화면 끝까지 이어지고 카드는 이 여백에서 시작한다.
  final double bleedInset;

  /// 지금 보는 교인. 디자인 견본에서는 null이라 저장소를 읽지 않는 견본 글로 그린다.
  final Member? me;

  final BlockConfig block;
  final List<ChurchContent> items;
  final void Function(ChurchContent) onOpen;
  final String hint;

  /// 카드 슬라이드 한 장의 너비. 높이는 이미지 비율(4:3)로 정해진다.
  static const cardWidth = 220.0;

  @override
  Widget build(BuildContext context) {
    final open = onOpen;
    final theme = BlockTheme.of(context, block);
    return switch (block.type) {
      BlockType.video => _video(items, open),
      BlockType.gallery => _gallery(items, stacked: block.variant == 'stack'),
      BlockType.devotion when block.variant == 'carousel' => DevotionCarousel(
        items: items,
        theme: theme,
        count: block.limit.clamp(1, 3),
        onOpen: open,
      ),
      BlockType.devotion => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final c in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: me == null
                  ? DevotionDesign(
                      variant: block.variant,
                      theme: theme,
                      content: c,
                      reflections: sampleReflections,
                    )
                  : DevotionBlockItem(
                      variant: block.variant,
                      theme: theme,
                      content: c,
                      me: me!,
                      onOpen: () => open(c),
                    ),
            ),
        ],
      ),
      BlockType.schedule =>
        block.variant == 'agenda'
            ? switch (block.style) {
                // 일정표는 스타일에 따라 모양도 달라진다: 목록(심플) · 티켓(파스텔) · 타임라인(네온).
                BlockStyle.simple => ColumnWrap(
                  wide: 2,
                  children: [
                    for (final e in items)
                      EventTile(content: e, onTap: () => open(e)),
                  ],
                ),
                BlockStyle.pastel => AgendaDesign(
                  variant: 'agenda_pastel',
                  theme: theme,
                  items: items,
                  onOpen: open,
                ),
                BlockStyle.neon => AgendaDesign(
                  variant: 'agenda_neon',
                  theme: theme,
                  items: items,
                  onOpen: open,
                ),
              }
            : MonthCalendar(
                events: items,
                onOpen: open,
                hint: hint,
                variant: block.variant,
                theme: theme,
              ),
      _ => _board(context, items, open),
    };
  }

  /// 유튜브 링크: 영상 카드 · 영상 목록 · 큰 영상 하나 + 나머지 목록.
  /// 갤러리: 사진이 있는 글만 앨범 카드로 모아 보여준다 (누르면 사진 열람 팝업).
  Widget _gallery(List<ChurchContent> items, {bool stacked = false}) {
    final withPhotos = [
      for (final a in items)
        if (a.imageUrls.isNotEmpty) a,
    ];
    if (withPhotos.isEmpty) return const EmptyHint('아직 올라온 사진이 없어요.');
    return ColumnWrap(
      wide: 2,
      narrow: 1,
      children: [
        for (final a in withPhotos)
          stacked ? StackedAlbumCard(album: a) : AlbumCard(album: a),
      ],
    );
  }

  Widget _video(List<ChurchContent> items, void Function(ChurchContent) open) {
    switch (block.variant) {
      case 'list':
        return Column(
          children: [
            for (final c in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: VideoRow(content: c, onTap: () => open(c)),
              ),
          ],
        );
      case 'featured':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SermonCard(content: items.first, onTap: () => open(items.first)),
            for (final c in items.skip(1))
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: VideoRow(content: c, onTap: () => open(c)),
              ),
          ],
        );
      default:
        return ColumnWrap(
          wide: 3,
          children: [
            for (final c in items) SermonCard(content: c, onTap: () => open(c)),
          ],
        );
    }
  }

  Widget _board(
    BuildContext context,
    List<ChurchContent> items,
    void Function(ChurchContent) open,
  ) {
    switch (block.variant) {
      // ---- 사진 + 글 ----
      case 'banner':
        return NoticeCarousel(notices: items, onOpen: open);
      case 'cards':
        // 옆으로 미는 카드: 4:3 사진 위에 제목.
        return SizedBox(
          height: cardWidth / kThumbnailAspect,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: bleedInset),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => SizedBox(
              width: cardWidth,
              child: PhotoTile(content: items[i], onTap: () => open(items[i])),
            ),
          ),
        );
      case 'tiles':
        return ColumnWrap(
          narrow: 2,
          children: [
            for (final c in items) PostTile(content: c, onTap: () => open(c)),
          ],
        );
      case 'feature':
        return Column(
          children: [
            for (final c in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: PostTile(
                  content: c,
                  aspect: 16 / 9,
                  onTap: () => open(c),
                ),
              ),
          ],
        );
      // ---- 글만 ----
      case 'table':
      case 'text':
      case 'compact':
        // 글만: 스타일·팔레트에 따라 색이 달라진다.
        return ThemedPosts(
          variant: block.variant,
          items: items,
          theme: BlockTheme.of(context, block),
          onOpen: open,
        );
      default:
        // 목록: 자료 종류에 맞는 카드로 그린다.
        final kind = block.source.kind;
        if (kind == ContentKind.photo) {
          return ColumnWrap(
            narrow: 2,
            children: [
              for (final c in items)
                AspectRatio(
                  aspectRatio: kThumbnailAspect,
                  child: PhotoTile(content: c, onTap: () => open(c)),
                ),
            ],
          );
        }
        return ColumnWrap(
          wide: kind == ContentKind.sermon ? 3 : 2,
          children: [
            for (final c in items)
              switch (c.kind) {
                ContentKind.sermon => SermonCard(
                  content: c,
                  onTap: () => open(c),
                ),
                ContentKind.devotion => DevotionCard(
                  content: c,
                  onTap: () => open(c),
                ),
                ContentKind.event => EventTile(
                  content: c,
                  onTap: () => open(c),
                ),
                _ => NoticeRow(content: c, onTap: () => open(c)),
              },
          ],
        );
    }
  }
}
