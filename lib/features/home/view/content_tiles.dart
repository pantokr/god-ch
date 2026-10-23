import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../data/models/church_content.dart';
import 'content_widgets.dart';

BoxDecoration _cardBox(BuildContext context) => BoxDecoration(
  color: context.palette.surface,
  border: Border.all(color: context.palette.border),
  borderRadius: BorderRadius.circular(AppRadius.card),
);

/// 일정 한 줄: 날짜 배지 + 제목 + 설명 첫 줄.
class EventTile extends StatelessWidget {
  const EventTile({super.key, required this.content, required this.onTap});

  final ChurchContent content;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = content.date;
    final firstLine = content.body.split('\n').first;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Ink(
        decoration: _cardBox(context),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            DateBadge(d),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${weekdayLabel(d)}요일${firstLine.isEmpty ? '' : ' · $firstLine'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.palette.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 사진첩 한 칸: 썸네일 + 제목.
class PhotoTile extends StatelessWidget {
  const PhotoTile({super.key, required this.content, required this.onTap});

  final ChurchContent content;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ContentImage(content.thumbnail),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 18, 10, 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0xB3000000)],
                  ),
                ),
                child: Text(
                  content.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 설교영상 카드: 유튜브 썸네일 + 재생 표시 + 제목 · 날짜.
class SermonCard extends StatelessWidget {
  const SermonCard({super.key, required this.content, required this.onTap});

  final ChurchContent content;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Ink(
        decoration: _cardBox(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ContentImage(
                      content.thumbnail,
                      icon: Icons.smart_display_outlined,
                    ),
                    const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        size: 44,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fmtDate(content.date),
                      style: TextStyle(
                        color: context.palette.muted,
                        fontSize: 12,
                      ),
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

/// 말씀묵상 카드: 말씀 구절(제목) + 묵상 미리보기.
class DevotionCard extends StatelessWidget {
  const DevotionCard({
    super.key,
    required this.content,
    required this.onTap,
    this.maxLines = 4,
  });

  final ChurchContent content;
  final VoidCallback onTap;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Ink(
        decoration: _cardBox(context),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.menu_book_outlined,
                  size: 18,
                  color: context.palette.accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    content.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontSize: 17),
                  ),
                ),
                Text(
                  fmtDate(content.date),
                  style: TextStyle(color: context.palette.muted, fontSize: 12),
                ),
              ],
            ),
            if (content.body.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                content.body,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                style: readingStyle(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 공지사항 한 줄 (목록용): 썸네일 + 제목 · 날짜.
class NoticeRow extends StatelessWidget {
  const NoticeRow({super.key, required this.content, required this.onTap});

  final ChurchContent content;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Ink(
        decoration: _cardBox(context),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.control),
              // 공지 썸네일은 3:4 고정.
              child: SizedBox(
                width: 60,
                height: 60 / kThumbnailAspect,
                child: ContentImage(
                  content.thumbnail,
                  icon: Icons.campaign_outlined,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fmtDate(content.date),
                    style: TextStyle(
                      color: context.palette.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
