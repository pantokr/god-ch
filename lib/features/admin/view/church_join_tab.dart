import 'package:flutter/material.dart';

import '../../../core/layout/page_frame.dart';
import '../../../data/models/member.dart';
import 'blocked_users_card.dart';
import 'church_visibility_card.dart';
import 'invite_code_card.dart';
import 'join_requirements_card.dart';

/// 교회 입장 관리: 노출(공개 탐색 / 비공개), 입장 시 필수 정보, 초대 코드(코드마다 역할 · 부서 · 일회용 · 유효기간).
class ChurchJoinTab extends StatelessWidget {
  const ChurchJoinTab({super.key, required this.me});

  final Member me;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: PageFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageTitle(title: '교회 입장 관리'),
            ChurchVisibilityCard(me: me),
            const SizedBox(height: 24),
            JoinRequirementsCard(me: me),
            const SizedBox(height: 24),
            InviteCodeCard(me: me),
            const SizedBox(height: 24),
            BlockedUsersCard(me: me),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
