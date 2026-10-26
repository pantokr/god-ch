import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../data/models/church_content.dart';
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

/// "글만" 표: 머리글 줄(제목 · 날짜) 아래에 한 줄씩.
class PostTable extends StatelessWidget {
  const PostTable({super.key, required this.items, required this.onOpen});

  final List<ChurchContent> items;
  final void Function(ChurchContent) onOpen;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final head = TextStyle(
      color: palette.muted,
      fontSize: 12,
      fontWeight: FontWeight.w700,
    );
    return Card(
      child: Column(
        children: [
          Container(
            color: palette.brand.withValues(alpha: 0.08),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(child: Text('제목', style: head)),
                Text('날짜', style: head),
              ],
            ),
          ),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            InkWell(
              onTap: () => onOpen(items[i]),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        items[i].title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      fmtDate(items[i].date),
                      style: TextStyle(color: palette.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
