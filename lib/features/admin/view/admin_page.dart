import 'package:flutter/material.dart';

import '../../../core/layout/page_frame.dart';
import '../../../core/layout/responsive.dart';
import '../../../data/models/member.dart';
import 'department_admin_tab.dart';
import 'member_admin_tab.dart';
import 'prayer_admin_tab.dart';

/// 교역자·관리자 전용 화면: 기도제목 관리, 교인 관리, 부서 관리.
class AdminPage extends StatelessWidget {
  const AdminPage({super.key, required this.me});

  final Member me;

  @override
  Widget build(BuildContext context) {
    final pad = pagePadding(context);
    return DefaultTabController(
      length: 3,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kContentWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 28),
                const PageTitle(title: '관리', subtitle: '기도제목, 교인, 부서를 관리해요.'),
                const TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(text: '기도제목'),
                    Tab(text: '교인'),
                    Tab(text: '부서'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      PrayerAdminTab(me: me),
                      MemberAdminTab(me: me),
                      DepartmentAdminTab(me: me),
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
