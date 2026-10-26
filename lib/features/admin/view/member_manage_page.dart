import 'package:flutter/material.dart';

import '../../../data/models/member.dart';
import 'church_join_tab.dart';
import 'church_members_tab.dart';

/// 교회 운영자의 인원 관리: 교회 회원 관리 / 교회 입장 관리 탭.
/// 앱 운영자의 교회 상세 화면과 같은 두 탭을 쓴다.
class MemberManagePage extends StatelessWidget {
  const MemberManagePage({super.key, required this.me});

  final Member me;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: '교회 회원 관리'),
              Tab(text: '교회 입장 관리'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ChurchMembersTab(me: me),
                ChurchJoinTab(me: me),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
