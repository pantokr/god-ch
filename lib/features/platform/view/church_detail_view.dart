import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../data/models/church.dart';
import '../../admin/view/church_join_tab.dart';
import '../../admin/view/church_members_tab.dart';
import '../../admin/view/department_manage_page.dart';
import 'church_info_form.dart';

/// 한 교회의 상세 관리: 교회 정보 / 교회 회원 관리 / 교회 입장 관리 / 부서.
/// 교회 회원 관리는 앱 운영자의 회원 관리와 같은 모양이다.
/// 앱 운영자는 교회에 소속되지 않으므로 교회 안의 글 내용은 이 화면에 나오지 않는다.
class ChurchDetailView extends StatelessWidget {
  const ChurchDetailView({super.key, required this.church});

  final Church church;

  @override
  Widget build(BuildContext context) {
    // 기존 교회 관리 화면(교인·초대 코드·부서)을 쓰기 위한 화면용 정보다 (소속이 아니다).
    final operator = AppScope.read(context).churchRegistry
        .operatorViewOf(church);
    return DefaultTabController(
      length: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: '교회 정보'),
              Tab(text: '교회 회원 관리'),
              Tab(text: '교회 입장 관리'),
              Tab(text: '부서'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ChurchInfoForm(church: church),
                ChurchMembersTab(me: operator),
                ChurchJoinTab(me: operator),
                DepartmentManagePage(me: operator),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
