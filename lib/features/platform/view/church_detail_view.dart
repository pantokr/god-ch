import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/format.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/church.dart';
import '../../../data/models/member.dart';
import '../../admin/view/department_admin_tab.dart';
import '../../admin/view/member_admin_tab.dart';
import '../view_model/church_summary_view_model.dart';

/// 한 교회의 상세 관리: 교회 정보 / 교인·초대 코드 / 부서.
/// 앱 운영자는 교회에 소속되지 않으므로 기도제목 내용은 이 화면에 나오지 않는다.
class ChurchDetailView extends StatelessWidget {
  const ChurchDetailView({super.key, required this.church});

  final Church church;

  @override
  Widget build(BuildContext context) {
    // 기존 교회 관리 화면(교인·초대 코드·부서)을 쓰기 위한 화면용 정보다 (소속이 아니다).
    final operator = AppScope.read(context).churchRegistry
        .operatorViewOf(church);
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: '교회 정보'),
              Tab(text: '교인 · 초대 코드'),
              Tab(text: '부서'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _InfoTab(church: church),
                MemberAdminTab(me: operator),
                DepartmentAdminTab(me: operator),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTab extends StatelessWidget {
  const _InfoTab({required this.church});

  final Church church;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ChurchSummaryViewModel>(
      create: (context) =>
          ChurchSummaryViewModel(AppScope.read(context).members, church.id),
      builder: (context, vm) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: StreamBuilder<List<Member>>(
              stream: vm.members,
              builder: (context, snap) {
                final members = snap.data ?? const <Member>[];
                final approved = members.where((m) => m.isApproved).length;
                final pending = members
                    .where((m) => m.status == MemberStatus.pending)
                    .length;
                final owners = members
                    .where((m) => m.isApproved && m.role == Role.admin)
                    .map((m) => m.name)
                    .join(', ');
                return Column(
                  children: [
                    _Row('교회 이름', church.name),
                    _Row('주소', church.address),
                    _Row('전화번호', church.phone.isEmpty ? '-' : church.phone),
                    _Row('등록일', fmtDate(church.createdAt)),
                    const Divider(height: 32),
                    _Row('교인', snap.hasData ? '$approved명' : '-'),
                    _Row('승인 대기', snap.hasData ? '$pending명' : '-'),
                    _Row(
                      '교회 운영자',
                      !snap.hasData
                          ? '-'
                          : (owners.isEmpty
                                ? '아직 없어요 (초대 코드로 들어온 교인을 교회 운영자로 지정하세요)'
                                : owners),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
