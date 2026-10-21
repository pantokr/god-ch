import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../data/models/member.dart';
import '../../../data/models/prayer.dart';
import 'prayer_detail_page.dart';
import 'reaction_bar.dart';

class PrayerCard extends StatelessWidget {
  const PrayerCard({
    super.key,
    required this.prayer,
    required this.me,
    required this.showReactions,
    this.subtitle,
  });

  final Prayer prayer;
  final Member me;
  final bool showReactions;

  /// 날짜 옆에 덧붙일 문구 (예: 교역자 화면의 작성자 이름).
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasBadge =
        prayer.departmentId != null || !prayer.isPublic || prayer.deleted;
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PrayerDetailPage(prayer: prayer, me: me),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasBadge) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (prayer.departmentId != null)
                      const _Badge(icon: Icons.groups_outlined, label: '부서'),
                    if (!prayer.isPublic)
                      const _Badge(icon: Icons.lock_outline, label: '교역자 전용'),
                    if (prayer.deleted)
                      const _Badge(icon: Icons.delete_outline, label: '삭제됨'),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Text(
                prayer.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                [fmtDate(prayer.createdAt), ?subtitle].join(' · '),
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Text(
                prayer.content,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(height: 1.55),
              ),
              if (prayer.hasUnreadResponse && prayer.authorId == me.id) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.mark_email_unread_outlined,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '교역자의 답변이 도착했어요',
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ],
                ),
              ],
              if (showReactions) ...[
                const SizedBox(height: 16),
                ReactionBar(churchId: me.churchId, prayerId: prayer.id),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.muted),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
