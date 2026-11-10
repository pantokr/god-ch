import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/layout/app_dialog.dart';
import '../../../core/layout/confirm_dialog.dart';
import '../../../core/layout/manage_list_row.dart';
import '../../../core/widgets/toast.dart';
import '../../../data/models/affiliation.dart';
import '../../../data/models/member.dart';
import '../../../data/models/position.dart';
import '../view_model/member_admin_view_model.dart';
import '../../../core/widgets/member_mark.dart';
import 'member_detail_dialog.dart';
import 'member_info_page.dart';
import 'pending_member_dialogs.dart';

/// 교인 한 명: 이름 · 수락일 · 소속을 보여주고, 관리를 누르면 역할 · 소속 · 상태를 고치는 창이 열린다.
/// 본인 줄에는 '본인' 표시가 붙는다. 관리 창에서 교회 운영자는 회원을 추방 · 차단할 수 있다.
/// 승인 대기 계정은 관리 대신 승인 · 거절 버튼이 있고, 승인하면 역할과 소속을 고르는 창이 뜬다.
class MemberTile extends StatelessWidget {
  const MemberTile({
    super.key,
    required this.member,
    required this.vm,
    this.affiliationNames = const [],
    this.affiliations = const [],
    this.isNew = false,
    this.position,
  });

  final Member member;
  final MemberAdminViewModel vm;

  /// 이 교인이 속한 소속 이름들.
  final List<String> affiliationNames;

  /// 이 교회의 소속 전체 (상세 관리 창에서 고를 목록).
  final List<Affiliation> affiliations;

  /// 새로 등록된 인원이면 이름 옆에 표시한다.
  final bool isNew;

  /// 이 교인이 가진 직급 (없으면 null). 직급의 아이콘과 색이 이름 앞에 보인다.
  final Position? position;

  @override
  Widget build(BuildContext context) {
    final pending = member.status == MemberStatus.pending;
    final isSelf = member.id == vm.me.id;
    // 괄호 안: ID로 가입했으면 아이디, Google로 가입했으면 줄인 이메일.
    final account = member.loginId.isNotEmpty
        ? member.loginId
        : shortEmail(member.email);
    final name = account.isEmpty ? member.name : '${member.name}  ($account)';
    // 새로 들어온 인원이든 등록된 인원이든 같은 줄 모양을 쓴다: 이름 · 소속 교회 · [승인] [관리].
    return ManageListRow(
      leading: ManageListRow.avatar(
        context,
        member.name,
        imageUrl: member.photoUrl,
      ),
      title: name,
      // 교회 관리자는 이름 앞에 왕관으로 따로 표시한다.
      titleMark: MemberMark(
        role: member.isAppOperator ? Role.member : member.role,
        position: position,
        roles: vm.me.rolePermissions,
      ),
      badge: isSelf
          ? '본인'
          : isNew
          ? 'NEW'
          : null,
      // 신규 입장 요청은 요청일, 교회 회원은 수락일(시작일)이 보인다.
      // 교회 회원은 직급만 보인다 (소속 · 수락일은 상세 페이지에서).
      line1: pending ? '요청일 ${fmtDate(member.createdAt)}' : '',
      affiliations: pending ? affiliationNames : const [],
      // 입장 요청은 줄을 누르면 그 사람의 상세 정보 페이지가 열린다 (승인 · 거절 버튼은 줄에 그대로 있다).
      onTap: pending ? () => _view(context) : null,
      trailing: [
        // 신규 입장 요청은 승인 · 거절 두 버튼뿐이다. 승인하면 역할과 소속을 고르는 창이 뜬다.
        if (pending) ...[
          if (vm.canChangeStatus(member))
            FilledButton.tonal(
              onPressed: () => _approve(context),
              child: const Text('승인'),
            ),
          // 거절은 교회 운영자만 (추방과 같다).
          if (vm.canDelete(member))
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => _confirmReject(context),
              child: const Text('거절'),
            ),
        ] else
          // 교회 회원은 관리 하나: 역할 · 소속 · 상태를 고친다.
          TextButton(onPressed: () => _edit(context), child: const Text('관리')),
      ],
    );
  }

  String get _positionName => memberPositionLabel(member, position: position);

  /// 승인: 역할과 소속을 고르는 창을 띄우고, 고른 대로 승인한다.
  Future<void> _approve(BuildContext context) async {
    final choice = await showAppDialog<ApproveChoice>(
      context,
      child: ApproveMemberDialog(
        member: member,
        affiliations: affiliations,
        canRole: vm.canChangeRole(member),
        canAffiliation: vm.canAssignAffiliation(member),
      ),
    );
    if (choice == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    // 소속을 고르지 못하는 사람이 승인하면 요청자가 가진 소속이 그대로다. 교회 관리자는 모든 소속에 속한다.
    final affiliated =
        choice.role == Role.admin ||
        (vm.canAssignAffiliation(member)
            ? choice.affiliationIds.isNotEmpty
            : member.affiliationIds.isNotEmpty);
    final ok = await vm.approveWith(
      member,
      role: choice.role,
      affiliationIds: choice.affiliationIds,
    );
    if (ok) {
      showToastOn(
        messenger,
        affiliated ? '승인했습니다.' : '미배정 소속으로 승인했습니다.',
        bottom: bottom,
      );
    }
  }

  /// 입장 요청 거절 확인 창. 거절했으면 true.
  Future<bool> _confirmReject(BuildContext context) async {
    final ok = await confirmChange(
      context,
      title: '입장 거절',
      body: '${member.name}님의 요청을 거절합니다',
      confirmLabel: '거절',
      danger: true,
    );
    if (!ok) return false;
    await vm.reject(member);
    return vm.error == null;
  }

  /// 추방 확인 창. 추방했으면 true.
  Future<bool> _confirmDelete(BuildContext context) async {
    final ok = await confirmChange(
      context,
      title: '회원 추방',
      body: '${member.name}님을 추방합니다',
      confirmLabel: '추방',
      danger: true,
    );
    if (!ok) return false;
    await vm.remove(member);
    return vm.error == null;
  }

  /// 차단 확인 창. 차단했으면 true.
  Future<bool> _confirmBlock(BuildContext context) async {
    final ok = await confirmChange(
      context,
      title: '회원 차단',
      body: '${member.name}님을 차단합니다',
      confirmLabel: '차단',
      danger: true,
    );
    if (!ok) return false;
    await vm.block(member);
    return vm.error == null;
  }

  /// 입장 요청한 사람의 상세 정보를 보기만 한다 (고치는 칸이 없다).
  void _view(BuildContext context) => showMemberInfoPage(
    context,
    member: member,
    positionName: _positionName,
    position: position,
    affiliationNames: affiliationNames,
  );

  void _edit(BuildContext context) {
    showMemberInfoPage(
      context,
      member: member,
      positionName: _positionName,
      position: position,
      affiliationNames: affiliationNames,
      editor: MemberDetailDialog(
        showHeader: false,
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
            affiliations: affiliations,
            canRole: vm.canChangeRole(member),
          ),
        ],
        onSave: (result) => vm.saveDetail(member, result),
        onRemove: vm.canDelete(member) ? () => _confirmDelete(context) : null,
        onBlock: vm.canDelete(member) ? () => _confirmBlock(context) : null,
      ),
    );
  }
}
