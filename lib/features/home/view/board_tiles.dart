import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../data/models/block_style.dart';
import '../../../data/models/church_content.dart';
import 'block_theme.dart';
import 'content_widgets.dart';

/// "사진 + 글" 카드: 위에 사진, 아래에 제목과 날짜. 사진 비율은 [aspect].
class PostTile extends StatelessWidget {
  const PostTile({
    super.key,
    required this.content,
    required this.onTap,
    this.aspect = kThumbnailAspect,
  });

  final ChurchContent content;
  final VoidCallback onTap;
  final double aspect;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final radius = BorderRadius.circular(AppRadius.card);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: radius,
        border: Border.all(color: palette.border.withValues(alpha: 0.7)),
        boxShadow: AppShadow.soft(context),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: aspect,
                  child: ContentImage(content.thumbnail),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        content.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fmtDate(content.date),
                        style: TextStyle(color: palette.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 게시판의 "글만" 디자인들. 스타일·팔레트([BlockTheme])에 따라 색이 달라진다.
/// - text: 제목 · 첫 줄 · 날짜.
/// - compact: 점 + 제목 + 날짜 한 줄.
/// - table: 머리글 줄(제목 · 날짜) 아래에 한 줄씩.
class ThemedPosts extends StatelessWidget {
  const ThemedPosts({
    super.key,
    required this.variant,
    required this.items,
    required this.theme,
    required this.onOpen,
  });

  final String variant;
  final List<ChurchContent> items;
  final BlockTheme theme;
  final void Function(ChurchContent) onOpen;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.card);
    return DecoratedBox(
      decoration: theme.card(),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            children: [
              if (variant == 'table') _head(),
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) Divider(height: 1, color: theme.border),
                InkWell(
                  onTap: () => onOpen(items[i]),
                  child: switch (variant) {
                    'compact' => _compact(items[i], i),
                    'table' => _tableRow(items[i]),
                    _ => _text(items[i]),
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  TextStyle get _date => TextStyle(color: theme.sub, fontSize: 13);

  Widget _head() {
    final style = TextStyle(
      color: theme.accent,
      fontSize: 12,
      fontWeight: FontWeight.w800,
    );
    return Container(
      color: theme.accent.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(child: Text('제목', style: style)),
          Text('날짜', style: style),
        ],
      ),
    );
  }

  Widget _text(ChurchContent c) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (c.body.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    c.body.split('\n').first,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.sub, fontSize: 13),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(fmtDate(c.date), style: _date),
      ],
    ),
  );

  Widget _compact(ChurchContent c, int i) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: theme.accentGradient,
            boxShadow: theme.style == BlockStyle.neon
                ? [
                    BoxShadow(
                      color: theme.accent.withValues(alpha: 0.8),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            c.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: theme.text),
          ),
        ),
        const SizedBox(width: 8),
        Text(fmtDate(c.date), style: _date),
      ],
    ),
  );

  Widget _tableRow(ChurchContent c) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(
      children: [
        Expanded(
          child: Text(
            c.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: theme.text),
          ),
        ),
        const SizedBox(width: 12),
        Text(fmtDate(c.date), style: _date),
      ],
    ),
  );
}
