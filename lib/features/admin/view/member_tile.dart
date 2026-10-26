import 'package:flutter/material.dart';

import '../../../core/layout/app_dialog.dart';
import '../../../core/layout/manage_list_row.dart';
import '../../../data/models/department.dart';
import '../../../data/models/member.dart';
import '../view_model/member_admin_view_model.dart';
import 'member_detail_dialog.dart';

/// 교인 한 명: 이름 · 소속 교회 · 소속 부서만 보여주고, 관리를 누르면 상세 관리 창이 열린다.
/// 승인 대기 계정은 같은 줄에서 바로 승인할 수 있다 (거절은 관리 창의 상태에서).
class MemberTile extends StatelessWidget {
  const MemberTile({
    super.key,
    required this.member,
    required this.vm,
    this.departmentNames = const [],
    this.departments = const [],
    this.isNew = false,
  });

  final Member member;
  final MemberAdminViewModel vm;

  /// 이 교인이 속한 부서 이름들.
  final List<String> departmentNames;

  /// 이 교회의 부서 전체 (상세 관리 창에서 고를 목록).
  final List<Department> departments;

  /// 새로 등록된 인원이면 이름 옆에 표시한다.
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final pending = member.status == MemberStatus.pending;
    final name = member.loginId.isEmpty
        ? member.name
        : '${member.name}  (${member.loginId})';
    // 새로 들어온 인원이든 등록된 인원이든 같은 줄 모양을 쓴다: 이름 · 소속 교회 · 소속 부서 · [승인] [관리].
    return ManageListRow(
      leading: ManageListRow.avatar(
        context,
        member.name,
        imageUrl: member.photoUrl,
      ),
      title: name,
      badge: isNew ? 'NEW' : null,
      line1: member.churchName,
      line2: departmentNames.join(', '),
      onTap: () => _edit(context),
      trailing: [
        if (pending && vm.canChangeStatus(member))
          FilledButton.tonal(
            onPressed: () => vm.approve(member),
            child: const Text('승인'),
          ),
        TextButton(onPressed: () => _edit(context), child: const Text('관리')),
      ],
    );
  }

  void _edit(BuildContext context) {
    showAppDialog(
      context,
      child: MemberDetailDialog(
        vm: vm,
        title: member.name,
        name: member.name,
        phone: member.phone,
        address: member.address,
        birthDate: member.birthDate,
        canEditProfile: vm.canEditProfile(member),
        memberships: [
          MembershipEditor(
            member: member,
            departments: departments,
            canRole: vm.canChangeRole(member),
            canStatus: vm.canChangeStatus(member),
          ),
        ],
        onSave: (result) => vm.saveDetail(member, result),
      ),
    );
  }
}
