import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/format.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/church_content.dart';
import '../../../data/models/department.dart';
import '../../../data/models/member.dart';
import '../../../data/models/page_layout.dart';
import '../../../data/models/prayer.dart';
import '../../prayers/view/prayer_list.dart';
import '../view_model/block_view_model.dart';
import 'board_tiles.dart';
import 'content_tiles.dart';
import 'devotion_designs.dart';
import 'content_widgets.dart';
import 'month_calendar.dart';
import 'neon_blocks.dart';
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
  });

  final BlockConfig block;
  final Member me;
  final Department? department;

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
            child: block.title.trim().isNotEmpty
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
    final hint = me.isAdmin ? '\n"콘텐츠 관리"에서 추가할 수 있어요.' : '';
    void open(ChurchContent c) =>
        context.push(Routes.contentDetail(me.churchId, c.kind, c.id));

    if (block.type == BlockType.messenger) {
      return _Messenger(
        stream: vm.prayers!,
        me: me,
        department: department,
        variant: block.variant,
        limit: block.limit,
      );
    }

    // 자료가 없거나 불러오는 중에도, 자료가 들어왔을 때와 같은 높이(이미지 4:3 기준)를 잡는다.
    return LayoutBuilder(
      builder: (context, box) {
        final reserved = _reservedHeight(context, box.maxWidth - inset * 2);
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

/// 메신저 구조: 중보기도 요청을 카드 또는 대화 말풍선으로 보여주고, 글쓰기 버튼을 둔다.
class _Messenger extends StatelessWidget {
  const _Messenger({
    required this.stream,
    required this.me,
    required this.department,
    required this.variant,
    required this.limit,
  });

  final Stream<List<Prayer>> stream;
  final Member me;
  final Department? department;
  final String variant;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final write = SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () =>
            context.push(Routes.newPrayer(me.churchId, dept: department?.id)),
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: const Text('기도제목 나누기'),
      ),
    );
    const empty = '아직 나눠진 기도제목이 없어요.\n첫 기도제목을 나눠 보세요.';

    final neon = NeonScheme.of(variant);
    if (neonShape(variant) != 'bubbles') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          write,
          const SizedBox(height: 16),
          PrayerGrid(
            prayers: stream,
            me: me,
            emptyText: empty,
            showReactions: true,
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        write,
        const SizedBox(height: 16),
        StreamBuilder<List<Prayer>>(
          stream: stream,
          builder: (context, snap) {
            if (snap.hasError) return Text('불러오지 못했습니다\n${snap.error}');
            final items = snap.data;
            if (items == null) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (items.isEmpty) return const EmptyHint(empty);
            return Column(
              children: [
                // 오래된 글이 위, 최근 글이 아래로 가는 대화 순서로 보여준다.
                for (final p in items.take(limit).toList().reversed)
                  if (neon != null)
                    NeonPrayerBubble(
                      scheme: neon,
                      prayer: p,
                      mine: p.authorId == me.id,
                      onTap: () => context.push(
                        Routes.prayer(me.churchId, p.id),
                        extra: p,
                      ),
                    )
                  else
                    PrayerBubble(prayer: p, me: me),
              ],
            );
          },
        ),
      ],
    );
  }
}

class PrayerBubble extends StatelessWidget {
  const PrayerBubble({super.key, required this.prayer, required this.me});

  final Prayer prayer;
  final Member me;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final mine = prayer.authorId == me.id;
    final radius = BorderRadius.circular(AppRadius.card + 2);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: mine
                ? palette.brand.withValues(alpha: 0.14)
                : palette.surface,
            borderRadius: radius,
            child: InkWell(
              borderRadius: radius,
              onTap: () => context.push(
                Routes.prayer(me.churchId, prayer.id),
                extra: prayer,
              ),
              child: Ink(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: palette.border),
                  borderRadius: radius,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prayer.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      prayer.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (prayer.createdAt != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        fmtDate(prayer.createdAt!),
                        style: TextStyle(color: palette.muted, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
    return switch (block.type) {
      BlockType.video => _video(items, open),
      BlockType.devotion => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final c in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: me == null
                  ? DevotionDesign(
                      variant: block.variant,
                      content: c,
                      reflections: sampleReflections,
                    )
                  : DevotionBlockItem(
                      variant: block.variant,
                      content: c,
                      me: me!,
                      onOpen: () => open(c),
                    ),
            ),
        ],
      ),
      BlockType.schedule =>
        block.variant == 'agenda'
            ? ColumnWrap(
                wide: 2,
                children: [
                  for (final e in items)
                    EventTile(content: e, onTap: () => open(e)),
                ],
              )
            : MonthCalendar(
                events: items,
                onOpen: open,
                hint: hint,
                variant: block.variant,
              ),
      _ => _board(context, items, open),
    };
  }

  /// 유튜브 링크: 영상 카드 · 영상 목록 · 큰 영상 하나 + 나머지 목록.
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
        return PostTable(items: items, onOpen: open);
      case 'text':
        // 사진 없이 제목 · 첫 줄 · 날짜만.
        return Card(
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                ListTile(
                  onTap: () => open(items[i]),
                  title: Text(
                    items[i].title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: items[i].body.trim().isEmpty
                      ? null
                      : Text(
                          items[i].body.split('\n').first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                  trailing: Text(
                    fmtDate(items[i].date),
                    style: TextStyle(
                      color: context.palette.muted,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      case 'compact':
        return Card(
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                ListTile(
                  dense: true,
                  onTap: () => open(items[i]),
                  title: Text(
                    items[i].title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    fmtDate(items[i].date),
                    style: TextStyle(
                      color: context.palette.muted,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
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
