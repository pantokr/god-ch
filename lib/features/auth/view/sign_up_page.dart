import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/formatters/korean_phone.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/blur_validated_field.dart';
import '../../../core/widgets/required_label.dart';
import '../data/auth_repository.dart';
import '../data/login_id.dart';
import '../view_model/sign_up_view_model.dart';
import 'consent_checkbox.dart';
import 'profile_extra_fields.dart';

/// 회원가입: ID, 비밀번호, 이름, 전화번호, (선택) 주소·생년월일, 개인정보 제3자 제공 동의.
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _form = GlobalKey<FormState>();
  final _loginId = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _birthDate = TextEditingController();
  bool _consent = false;

  @override
  void dispose() {
    _loginId.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _birthDate.dispose();
    super.dispose();
  }

  Future<void> _submit(SignUpViewModel vm) async {
    if (!_form.currentState!.validate()) return;
    await vm.submit(
      SignUpData(
        loginId: _loginId.text,
        password: _password.text,
        name: _name.text,
        phone: _phone.text,
        address: _address.text,
        birthDate: _birthDate.text,
        consentThirdParty: _consent,
      ),
    );
    // 가입하면 로그인된 상태가 되므로, 라우터가 알아서 내 교회 화면으로 보낸다.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ViewModelBuilder<SignUpViewModel>(
      create: (context) => SignUpViewModel(AppScope.read(context).auth),
      // 상단 바 없이 로그인 화면처럼 가운데에 고정 폭 패널만 놓는다.
      builder: (context, vm) => Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.panel),
                  side: BorderSide(color: context.palette.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _FieldGroup(
                          title: '로그인 정보',
                          children: [
                            BlurValidatedField(
                              controller: _loginId,
                              autocorrect: false,
                              maxLength: 20,
                              decoration: InputDecoration(
                                label: const RequiredLabel('아이디'),
                              ),
                              validator: (v) => LoginId.validate(v ?? ''),
                            ),
                            BlurValidatedField(
                              controller: _password,
                              onChanged: (_) => setState(() {}),
                              obscureText: true,
                              decoration: InputDecoration(
                                label: const RequiredLabel('비밀번호'),
                                suffixText: '8자 이상',
                              ),
                              validator: (v) => (v == null || v.length < 8)
                                  ? '8자 이상 입력해 주세요'
                                  : null,
                            ),
                            BlurValidatedField(
                              controller: _passwordConfirm,
                              obscureText: true,
                              decoration: InputDecoration(
                                label: const RequiredLabel('비밀번호 확인'),
                              ),
                              validator: (v) =>
                                  v != _password.text ? '비밀번호가 일치하지 않아요' : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _FieldGroup(
                          title: '기본 정보',
                          children: [
                            BlurValidatedField(
                              controller: _name,
                              maxLength: 30,
                              decoration: InputDecoration(
                                label: const RequiredLabel('이름'),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? '이름을 입력해 주세요'
                                  : null,
                            ),
                            BlurValidatedField(
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              inputFormatters: const [KoreanPhoneFormatter()],
                              decoration: InputDecoration(
                                label: const RequiredLabel('전화번호'),
                                hintText: '010-1234-5678',
                              ),
                              validator: (v) =>
                                  (v == null || !isValidKoreanPhone(v))
                                  ? '전화번호 형식이 올바르지 않아요'
                                  : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _FieldGroup(
                          title: '추가 정보 (선택)',
                          description: '비워 두어도 가입할 수 있어요',
                          children: [
                            ProfileExtraFields(
                              address: _address,
                              birthDate: _birthDate,
                            ),
                          ],
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
                          child: const Text('가입하기'),
                        ),
                        if (!_consent)
                          Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              '필수 항목에 동의하면 가입할 수 있어요.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: context.palette.muted,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: vm.busy
                              ? null
                              : () => context.canPop()
                                    ? context.pop()
                                    : context.go(Routes.login),
                          child: const Text('이미 계정이 있어요 · 로그인'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 가입 화면의 입력란 묶음: 제목 줄(오른쪽에 짧은 안내) 아래에 밑줄형 입력란을 쌓는다.
class _FieldGroup extends StatelessWidget {
  const _FieldGroup({
    required this.title,
    required this.children,
    this.description,
  });

  final String title;
  final String? description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            if (description != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  description!,
                  textAlign: TextAlign.end,
                  style: TextStyle(color: palette.muted, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          children[i],
        ],
      ],
    );
  }
}
