import '../../../core/icons.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../data/models/member.dart';
import '../../../data/models/prayer.dart';
import 'reaction_bar.dart';

class PrayerCard extends StatelessWidget {
  const PrayerCard({
    super.key,
    required this.prayer,
    required this.me,
    required this.showReactions,
    this.subtitle,
    this.flat = false,
  });

  final Prayer prayer;
  final Member me;
  final bool showReactions;

  /// 날짜 옆에 덧붙일 문구 (예: 교역자 화면의 작성자 이름).
  final String? subtitle;

  /// 카드 틀 없이 화면 전체 폭의 한 줄로 그린다.
  final bool flat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasBadge =
        prayer.affiliationId != null || !prayer.isPublic || prayer.deleted;
    final body = InkWell(
      // 주소로 이동하므로 브라우저 뒤로가기로 목록에 돌아온다. 이미 가진 글은 함께 넘겨 바로 보여준다.
      onTap: () =>
          context.push(Routes.prayer(me.churchId, prayer.id), extra: prayer),
      child: Padding(
        padding: EdgeInsets.all(flat ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasBadge) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (prayer.affiliationId != null)
                    const _Badge(icon: AppIcons.usersThree, label: '소속'),
                  if (prayer.affiliationId != null)
                    const _Badge(icon: AppIcons.usersThree, label: '소속'),
                  if (!prayer.isPublic)
                    const _Badge(icon: AppIcons.lock, label: '교역자 전용'),
                  if (prayer.deleted)
                    const _Badge(icon: AppIcons.trash, label: '삭제됨'),
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
              [fmtDateTime(prayer.createdAt), ?subtitle].join(' · '),
              style: TextStyle(color: context.palette.muted, fontSize: 13),
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
                    AppIcons.envelopeSimple,
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
    );
    return flat ? body : Card(child: body);
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
        color: context.palette.bg,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.palette.muted),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: context.palette.muted),
          ),
        ],
      ),
    );
  }
}
