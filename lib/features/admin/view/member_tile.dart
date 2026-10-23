import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../data/models/member.dart';
import '../view_model/member_admin_view_model.dart';

/// 교인 한 명. 승인 대기 계정은 바로 승인할 수 있게 버튼을 드러낸다.
class MemberTile extends StatelessWidget {
  const MemberTile({
    super.key,
    required this.member,
    required this.vm,
    this.departmentNames = const [],
    this.isNew = false,
  });

  final Member member;
  final MemberAdminViewModel vm;

  /// 이 교인이 속한 부서 이름들.
  final List<String> departmentNames;

  /// 새로 등록된 인원이면 이름 옆에 표시한다.
  final bool isNew;

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

    final muted = TextStyle(color: context.palette.muted, fontSize: 13);

    // 한 칸 안에서 이름 · 정보 · 버튼이 아래로 쌓여서 좁은 화면에서도 넘치지 않는다.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  member.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (isNew) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: context.palette.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.control),
                  ),
                  child: Text(
                    'NEW',
                    style: TextStyle(
                      color: context.palette.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (canStatus || canRole) _menu(canStatus, canRole, pending),
            ],
          ),
          // 전화번호는 교인이 교회에 제공하는 것에 동의한 정보다.
          Text(member.phone.isEmpty ? '전화번호 없음' : member.phone, style: muted),
          Text(
            '${_roleLabel[member.role]} · ${_statusLabel[member.status]}',
            style: muted,
          ),
          Text(
            [
              if (member.createdAt != null) '가입 ${fmtDate(member.createdAt)}',
              departmentNames.isEmpty ? '부서 없음' : departmentNames.join(', '),
            ].join(' · '),
            style: muted,
          ),
          if (pending && canStatus)
            Padding(
              padding: const EdgeInsets.only(top: 10, right: 12),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => vm.approve(member),
                      child: const Text('승인'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => vm.disable(member),
                      child: const Text('거절'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _menu(bool canStatus, bool canRole, bool pending) {
    return PopupMenuButton<VoidCallback>(
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
    );
  }
}
