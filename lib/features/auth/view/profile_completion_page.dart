import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/formatters/korean_phone.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../view_model/profile_completion_view_model.dart';
import 'consent_checkbox.dart';

/// Google로 처음 로그인한 회원이 가입에 필요한 정보(이름, 전화번호, 동의)를 입력한다.
/// 저장하면 프로필이 만들어져 자동으로 다음 화면으로 넘어간다.
class ProfileCompletionPage extends StatefulWidget {
  const ProfileCompletionPage({super.key});

  @override
  State<ProfileCompletionPage> createState() => _ProfileCompletionPageState();
}

class _ProfileCompletionPageState extends State<ProfileCompletionPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _consent = false;
  bool _nameSeeded = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _submit(ProfileCompletionViewModel vm) {
    if (!_form.currentState!.validate()) return;
    vm.submit(name: _name.text, phone: _phone.text, consent: _consent);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ViewModelBuilder<ProfileCompletionViewModel>(
      create: (context) {
        final scope = AppScope.read(context);
        return ProfileCompletionViewModel(scope.profiles, scope.auth);
      },
      builder: (context, vm) {
        // Google 계정 이름을 기본값으로 한 번만 채운다.
        if (!_nameSeeded) {
          _name.text = vm.suggestedName;
          _nameSeeded = true;
        }
        return Scaffold(
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Form(
                      key: _form,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '가입 정보를 입력해 주세요',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Google 계정(${vm.email})으로 처음 오셨어요. 아래 정보를 입력하면 가입이 끝나요.',
                            style: const TextStyle(color: AppColors.muted),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _name,
                            maxLength: 30,
                            decoration: const InputDecoration(labelText: '이름'),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? '이름을 입력해 주세요'
                                : null,
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            inputFormatters: const [KoreanPhoneFormatter()],
                            decoration: const InputDecoration(
                              labelText: '전화번호',
                              hintText: '010-1234-5678',
                            ),
                            validator: (v) =>
                                (v == null || !isValidKoreanPhone(v))
                                ? '전화번호 형식이 올바르지 않아요'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          ConsentCheckbox(
                            value: _consent,
                            onChanged: (v) => setState(() => _consent = v),
                          ),
                          if (vm.error != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              vm.error!,
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ],
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: (vm.busy || !_consent)
                                ? null
                                : () => _submit(vm),
                            child: const Text('가입 완료'),
                          ),
                          TextButton(
                            onPressed: vm.signOut,
                            child: const Text('다른 계정으로 로그인'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
