import '../../../core/icons.dart';

import 'package:flutter/material.dart';

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
    // 카드 전체가 누르는 곳이다 (안의 교회 탈퇴 버튼은 따로 눌린다. 교회 정보 수정은 서랍의 교회 정보 관리에서 한다).
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
                          style: theme.textTheme.titleMedium?.copyWith(),
                        ),
                        Text(switch (member.role) {
                          Role.admin => '교회 관리자',
                          Role.staff => '교역자',
                          Role.member => '교인',
                        }, style: TextStyle(color: context.palette.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 교회 관리자는 탈퇴할 수 없다 (맡을 사람이 없어지므로).
            // 탈퇴는 줄 전체가 누르는 곳이다 (카드를 누르는 것과 따로 눌린다).
            if (member.role != Role.admin)
              InkWell(
                onTap: () => leaveChurch(context, member),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                  child: Row(
                    children: [
                      Icon(
                        AppIcons.signOut,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '교회 탈퇴',
                        style: TextStyle(color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
