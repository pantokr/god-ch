import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_scope.dart';
import '../../../core/format.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/invite_code.dart';
import '../../../data/models/member.dart';
import '../../church/data/church_repository.dart';
import '../view_model/invite_codes_view_model.dart';

/// 교인에게 알려줄 초대 코드. 코드는 일정 기간만 유효하고, 필요하면 새로 발급하거나 폐기한다.
class InviteCodeCard extends StatelessWidget {
  const InviteCodeCard({super.key, required this.me});

  final Member me;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<InviteCodesViewModel>(
      create: (context) =>
          InviteCodesViewModel(AppScope.read(context).churches, me),
      builder: (context, vm) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.vpn_key_outlined),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '초대 코드',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: vm.busy ? null : vm.create,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      '새 코드 만들기 (${ChurchRepository.inviteValidity.inDays}일 유효)',
                    ),
                  ),
                ],
              ),
              if (vm.error != null) ...[
                const SizedBox(height: 8),
                Text(
                  vm.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 12),
              StreamBuilder<List<InviteCode>>(
                stream: vm.codes,
                builder: (context, snap) {
                  final active = (snap.data ?? const <InviteCode>[])
                      .where((c) => !c.isExpired)
                      .toList();
                  if (active.isEmpty) {
                    return Text(
                      '유효한 초대 코드가 없어요. 새 코드를 만들어 교인에게 알려 주세요.',
                      style: TextStyle(color: context.palette.muted),
                    );
                  }
                  return Column(
                    children: [
                      for (final c in active) _CodeRow(code: c, vm: vm),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeRow extends StatelessWidget {
  const _CodeRow({required this.code, required this.vm});

  final InviteCode code;
  final InviteCodesViewModel vm;

  /// "3일 남음" / "5시간 남음" 처럼 남은 유효기간을 보여준다.
  String _remaining() {
    final left = code.expiresAt.difference(DateTime.now());
    if (left.inDays >= 1) {
      return '${left.inDays}일 남음 · ${fmtDate(code.expiresAt)}까지';
    }
    if (left.inHours >= 1) return '${left.inHours}시간 남음';
    return '곧 만료';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: SelectableText(
        code.code,
        style: const TextStyle(
          fontSize: 20,
          letterSpacing: 3,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(_remaining()),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code.code));
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('초대 코드를 복사했어요.')));
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('복사'),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: vm.busy ? null : () => vm.revoke(code.code),
            child: const Text('폐기'),
          ),
        ],
      ),
    );
  }
}
