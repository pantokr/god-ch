import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/icons.dart';
import '../../../core/layout/app_dialog.dart';
import '../../../core/layout/manage_list_row.dart';
import '../../../data/models/affiliation.dart';
import '../../../data/models/member.dart';
import '../view_model/member_admin_view_model.dart';
import 'member_detail_dialog.dart';

/// 교인 한 명: 이름 · 소속 교회 · 소속만 보여주고, 관리를 누르면 상세 관리 창이 열린다.
/// 본인 줄에는 '본인' 표시가 붙는다. 관리 창에서 교회 운영자는 회원을 추방할 수 있다.
/// 승인 대기 계정은 같은 줄에서 바로 승인할 수 있다 (거절은 관리 창의 상태에서).
class MemberTile extends StatelessWidget {
  const MemberTile({
    super.key,
    required this.member,
    required this.vm,
    this.affiliationNames = const [],
    this.affiliations = const [],
    this.isNew = false,
  });

  final Member member;
  final MemberAdminViewModel vm;

  /// 이 교인이 속한 소속 이름들.
  final List<String> affiliationNames;

  /// 이 교회의 소속 전체 (상세 관리 창에서 고를 목록).
  final List<Affiliation> affiliations;

  /// 새로 등록된 인원이면 이름 옆에 표시한다.
  final bool isNew;

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
      titleMark: member.role == Role.admin && !member.isAppOperator
          ? const Tooltip(
              message: '교회 관리자',
              child: Icon(AppIcons.crown, size: 18, color: Color(0xFFE0A100)),
            )
          : null,
      badge: isSelf
          ? '본인'
          : isNew
          ? 'NEW'
          : null,
      line1: member.churchName,
      line2: affiliationNames.join(', '),
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

  /// 추방 확인 창. 추방했으면 true.
  Future<bool> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('회원 추방'),
        content: Text('${member.name}님을 추방할까요?\n다시 들어오려면 초대 코드로 새로 신청해야 해요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('추방'),
          ),
        ],
      ),
    );
    if (ok != true) return false;
    await vm.remove(member);
    return vm.error == null;
  }

  /// 차단 확인 창. 차단했으면 true.
  Future<bool> _confirmBlock(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('회원 차단'),
        content: Text(
          '${member.name}님을 차단할까요?\n교회에서 내보내고, 이 교회에는 다시 입장할 수 없어요. 차단 목록에서 풀 수 있어요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('차단'),
          ),
        ],
      ),
    );
    if (ok != true) return false;
    await vm.block(member);
    return vm.error == null;
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
            affiliations: affiliations,
            canRole: vm.canChangeRole(member),
            canStatus: vm.canChangeStatus(member),
          ),
        ],
        onSave: (result) => vm.saveDetail(member, result),
        onRemove: vm.canDelete(member) ? () => _confirmDelete(context) : null,
        onBlock: vm.canDelete(member) ? () => _confirmBlock(context) : null,
      ),
    );
  }
}
