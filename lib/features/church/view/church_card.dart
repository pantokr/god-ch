import '../../../core/icons.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';

import '../../../core/theme.dart';
import '../../../data/models/member.dart';
import 'leave_church.dart';

/// 내 교회 한 곳: 누르면 그 교회로 들어간다.
class ChurchCard extends StatelessWidget {
  const ChurchCard({super.key, required this.member, required this.onOpen});

  final Member member;
  final void Function(Member church) onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 카드 전체가 누르는 곳이다 (안의 교회 수정 · 교회 탈퇴 버튼은 각자 눌린다).
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onOpen(member),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: context.palette.brand.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.control),
                    ),
                    child: Icon(
                      AppIcons.churchFill,
                      color: context.palette.brand,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.churchName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(switch (member.role) {
                          Role.admin => '교회 관리자',
                          Role.staff => '교역자',
                          Role.member => '교인',
                        }, style: TextStyle(color: context.palette.muted)),
                      ],
                    ),
                  ),
                  Icon(AppIcons.arrowRight, color: context.palette.muted),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Wrap(
                children: [
                  // 교회 정보는 그 교회의 관리자만 고친다.
                  if (member.role == Role.admin)
                    TextButton.icon(
                      onPressed: () => context.push(
                        Routes.section(member.churchId, ChurchSection.info),
                      ),
                      icon: const Icon(AppIcons.pencilSimple, size: 18),
                      label: const Text('교회 수정'),
                    ),
                  // 교회 관리자는 탈퇴할 수 없다 (맡을 사람이 없어지므로).
                  if (member.role != Role.admin)
                    TextButton.icon(
                      onPressed: () => leaveChurch(context, member),
                      icon: const Icon(AppIcons.signOut, size: 18),
                      label: const Text('교회 탈퇴'),
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
