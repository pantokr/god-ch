import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/widgets/blur_validated_field.dart';
import '../../../core/widgets/required_label.dart';
import '../data/password_rule.dart';
import '../view_model/change_password_view_model.dart';

/// 비밀번호 수정 팝업: 현재 비밀번호를 확인하고 새 비밀번호를 두 번 입력한다.
/// 새 비밀번호는 회원가입과 같은 규칙([PasswordRule])과 같은 입력 검사(입력칸을 벗어날 때)를 쓴다.
class ChangePasswordForm extends StatefulWidget {
  const ChangePasswordForm({super.key, this.onDone});

  /// 비밀번호를 바꾼 뒤 부른다 (팝업이면 닫는다).
  final VoidCallback? onDone;

  @override
  State<ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<ChangePasswordForm> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit(ChangePasswordViewModel vm) async {
    if (!_form.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    if (await vm.change(_current.text, _next.text, _confirm.text)) {
      _form.currentState?.reset();
      _current.clear();
      _next.clear();
      _confirm.clear();
      messenger.showSnackBar(const SnackBar(content: Text('비밀번호를 바꿨어요.')));
      widget.onDone?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ViewModelBuilder<ChangePasswordViewModel>(
      create: (context) => ChangePasswordViewModel(AppScope.read(context).auth),
      builder: (context, vm) => Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('비밀번호 수정', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            BlurValidatedField(
              controller: _current,
              obscureText: true,
              decoration: InputDecoration(
                label: const RequiredLabel('현재 비밀번호'),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? '현재 비밀번호를 입력해 주세요' : null,
            ),
            BlurValidatedField(
              controller: _next,
              onChanged: (_) => setState(() {}),
              obscureText: true,
              decoration: InputDecoration(label: const RequiredLabel('새 비밀번호')),
              validator: PasswordRule.validate,
            ),
            BlurValidatedField(
              controller: _confirm,
              obscureText: true,
              decoration: InputDecoration(
                label: const RequiredLabel('새 비밀번호 확인'),
              ),
              validator: (v) => PasswordRule.confirm(v, _next.text),
            ),
            if (vm.error != null) ...[
              const SizedBox(height: 12),
              Text(vm.error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: vm.busy ? null : () => _submit(vm),
                child: const Text('비밀번호 바꾸기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
