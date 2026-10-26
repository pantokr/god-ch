import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/profile_field.dart';
import '../../auth/view/profile_extra_fields.dart';
import '../view_model/join_church_view_model.dart';

/// 초대 코드를 입력해 교회 입장을 신청한다. 코드는 발급 후 일정 기간만 유효하다.
class JoinChurchDialog extends StatefulWidget {
  const JoinChurchDialog({super.key});

  @override
  State<JoinChurchDialog> createState() => _JoinChurchDialogState();
}

class _JoinChurchDialogState extends State<JoinChurchDialog> {
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _address = TextEditingController();
  final _birthDate = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    _address.dispose();
    _birthDate.dispose();
    super.dispose();
  }

  Future<void> _submit(JoinChurchViewModel vm) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (!_form.currentState!.validate()) return;
    if (await vm.submit(
      _code.text,
      address: _address.text,
      birthDate: _birthDate.text,
    )) {
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('입장을 신청했어요. 교역자의 승인을 기다려 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ViewModelBuilder<JoinChurchViewModel>(
      create: (context) => JoinChurchViewModel(AppScope.read(context).churches),
      builder: (context, vm) => Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('초대 코드로 입장', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              '교회에서 받은 초대 코드를 입력하세요. 코드는 발급 후 7일 동안만 유효해요.',
              style: TextStyle(color: context.palette.muted),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _code,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: '초대 코드'),
              readOnly: vm.missing.isNotEmpty,
              onFieldSubmitted: (_) => _submit(vm),
            ),
            if (vm.missing.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                '${vm.missingChurch}에서 ${vm.missing.map((f) => f.label).join('·')} 입력을 요청했어요. 입력하면 회원 정보에도 저장돼요.',
                style: TextStyle(color: context.palette.muted),
              ),
              const SizedBox(height: 12),
              ProfileExtraFields(
                address: _address,
                birthDate: _birthDate,
                showAddress: vm.missing.contains(ProfileField.address),
                showBirthDate: vm.missing.contains(ProfileField.birthDate),
                requireAddress: true,
                requireBirthDate: true,
              ),
            ],
            if (vm.error != null && vm.missing.isEmpty) ...[
              const SizedBox(height: 12),
              Text(vm.error!, style: TextStyle(color: theme.colorScheme.error)),
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
                FilledButton(
                  onPressed: vm.busy ? null : () => _submit(vm),
                  child: const Text('입장 신청'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
