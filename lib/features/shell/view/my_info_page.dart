import 'package:flutter/material.dart';

import '../../../core/layout/page_frame.dart';
import '../../../core/layout/profile_summary.dart';
import '../../../data/models/member.dart';

/// 모바일 하단 탭의 "내 정보": 프로필, 내 교회 목록으로 돌아가기, 로그아웃.
/// 데스크톱에서는 상단 바의 "내 정보"·"로그아웃" 버튼이 같은 역할을 한다.
class MyInfoPage extends StatelessWidget {
  const MyInfoPage({
    super.key,
    required this.me,
    required this.userName,
    required this.userEmail,
    required this.onBack,
    required this.onSignOut,
  });

  final Member me;
  final String userName;
  final String userEmail;
  final VoidCallback onBack;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: PageFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageTitle(title: '내 정보'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ProfileSummary(
                  name: userName,
                  email: userEmail,
                  details: profileDetailsOf(me),
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.church_outlined, size: 18),
              label: const Text('내 교회 목록으로'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onSignOut,
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('로그아웃'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 내 정보에 보여줄 교회 / 역할 항목.
List<ProfileDetail> profileDetailsOf(Member me) => [
  ProfileDetail('교회', me.churchName),
  ProfileDetail('역할', switch (me.role) {
    Role.admin => '교회 운영자',
    Role.staff => '교역자',
    Role.member => '교인',
  }),
];
