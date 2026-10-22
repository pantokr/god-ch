import 'package:flutter/material.dart';

import '../../../data/models/member.dart';
import '../view_model/member_admin_view_model.dart';

/// 교인 한 명. 승인 대기 계정은 바로 승인할 수 있게 버튼을 드러낸다.
class MemberTile extends StatelessWidget {
  const MemberTile({super.key, required this.member, required this.vm});

  final Member member;
  final MemberAdminViewModel vm;

  static const _roleLabel = {
    Role.member: '교인',
    Role.staff: '교역자',
    Role.admin: '교회 운영자',
  };
  static const _statusLabel = {
    MemberStatus.pending: '승인 대기',
    MemberStatus.approved: '승인됨',
    MemberStatus.disabled: '비활성',
  };

  @override
  Widget build(BuildContext context) {
    final canStatus = vm.canChangeStatus(member);
    final canRole = vm.canChangeRole(member);
    final pending = member.status == MemberStatus.pending;

    return ListTile(
      title: Text(member.name),
      subtitle: Text(
        // 전화번호는 교인이 교회에 제공하는 것에 동의한 정보다.
        '${member.email}${member.phone.isEmpty ? '' : ' · ${member.phone}'}\n'
        '${_roleLabel[member.role]} · ${_statusLabel[member.status]}',
      ),
      isThreeLine: true,
      trailing: (canStatus || canRole)
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (pending && canStatus)
                  FilledButton(
                    onPressed: () => vm.approve(member),
                    child: const Text('승인'),
                  ),
                PopupMenuButton<VoidCallback>(
                  tooltip: '더 보기',
                  onSelected: (action) => action(),
                  itemBuilder: (context) => [
                    if (canStatus && member.status != MemberStatus.approved)
                      PopupMenuItem(
                        value: () => vm.approve(member),
                        child: Text(pending ? '가입 승인' : '다시 활성화'),
                      ),
                    if (canStatus && member.status != MemberStatus.disabled)
                      PopupMenuItem(
                        value: () => vm.disable(member),
                        child: Text(pending ? '가입 거절' : '계정 비활성화'),
                      ),
                    if (canRole && member.role != Role.member)
                      PopupMenuItem(
                        value: () => vm.setRole(member, Role.member),
                        child: const Text('일반 교인으로 변경'),
                      ),
                    if (canRole && member.role != Role.staff)
                      PopupMenuItem(
                        value: () => vm.setRole(member, Role.staff),
                        child: const Text('교역자로 지정'),
                      ),
                    if (canRole && member.role != Role.admin)
                      PopupMenuItem(
                        value: () => vm.setRole(member, Role.admin),
                        child: const Text('교회 운영자로 지정'),
                      ),
                  ],
                ),
              ],
            )
          : null,
    );
  }
}
