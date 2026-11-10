import 'package:flutter/material.dart';

import '../../../core/icons.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_inputs.dart';
import '../../../data/models/affiliation.dart';
import '../../../data/models/member.dart';

/// 승인할 때 고른 역할과 소속.
class ApproveChoice {
  const ApproveChoice(this.role, this.affiliationIds);

  final Role role;
  final List<String> affiliationIds;
}

/// 승인 창: 역할과 소속을 고르고 승인한다. 승인하면 [ApproveChoice]를 돌려준다.
/// [canRole]이 false면 역할은 교인으로 고정이고, [canAffiliation]이 false면 소속은 고르지 못한다.
class ApproveMemberDialog extends StatefulWidget {
  const ApproveMemberDialog({
    super.key,
    required this.member,
    required this.affiliations,
    required this.canRole,
    required this.canAffiliation,
  });

  final Member member;
  final List<Affiliation> affiliations;
  final bool canRole;
  final bool canAffiliation;

  @override
  State<ApproveMemberDialog> createState() => _ApproveMemberDialogState();
}

class _ApproveMemberDialogState extends State<ApproveMemberDialog> {
  late Role _role = widget.member.role;
  late final Set<String> _affs = {...widget.member.affiliationIds};

  static const _roleLabel = {
    Role.member: '교인',
    Role.staff: '교역자',
    Role.admin: '교회 관리자',
  };

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(color: context.palette.muted);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${widget.member.name} 승인',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        if (widget.canRole)
          AppDropdown<Role>(
            value: _role,
            label: '역할',
            items: [
              for (final r in Role.values)
                DropdownMenuItem(value: r, child: Text(_roleLabel[r]!)),
            ],
            onChanged: (v) => setState(() => _role = v!),
          ),
        if (widget.canAffiliation) ...[
          const SizedBox(height: 12),
          Text('소속', style: muted),
          if (widget.affiliations.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('만들어진 소속이 없어요.', style: muted),
            ),
          for (final a in widget.affiliations)
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(a.name),
              // 교회 운영자는 모든 소속에 자동으로 속한다.
              value: _role == Role.admin || _affs.contains(a.id),
              onChanged: _role == Role.admin
                  ? null
                  : (v) => setState(() {
                      if (v ?? false) {
                        _affs.add(a.id);
                      } else {
                        _affs.remove(a.id);
                      }
                    }),
            ),
        ],
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () =>
                  Navigator.pop(context, ApproveChoice(_role, [..._affs])),
              icon: const Icon(AppIcons.check, size: 18),
              label: const Text('승인'),
            ),
          ],
        ),
      ],
    );
  }
}
