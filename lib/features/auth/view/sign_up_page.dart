import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/formatters/korean_phone.dart';
import '../../../core/layout/sub_page.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../data/auth_repository.dart';
import '../data/login_id.dart';
import '../view_model/sign_up_view_model.dart';
import 'consent_checkbox.dart';

/// 회원가입: ID, 비밀번호, 이름, 이메일(인증 메일 발송), 전화번호, 개인정보 제3자 제공 동의.
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
  bool _consent = false;

  @override
  void dispose() {
    _loginId.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    _name.dispose();
    _phone.dispose();
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
      builder: (context, vm) => SubPage(
        title: '회원가입',
        fallbackLocation: Routes.login,
        maxWidth: 520,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _loginId,
                    autocorrect: false,
                    maxLength: 20,
                    decoration: const InputDecoration(
                      labelText: '아이디',
                      helperText: '영문 소문자로 시작, 영문 소문자·숫자·_ 4~20자',
                    ),
                    validator: (v) => LoginId.validate(v ?? ''),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '비밀번호',
                      helperText: '8자 이상',
                    ),
                    validator: (v) =>
                        (v == null || v.length < 8) ? '8자 이상 입력해 주세요' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordConfirm,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: '비밀번호 확인'),
                    validator: (v) =>
                        v != _password.text ? '비밀번호가 일치하지 않아요' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _name,
                    maxLength: 30,
                    decoration: const InputDecoration(labelText: '이름'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? '이름을 입력해 주세요' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    inputFormatters: const [KoreanPhoneFormatter()],
                    decoration: const InputDecoration(
                      labelText: '전화번호',
                      hintText: '010-1234-5678',
                    ),
                    validator: (v) => (v == null || !isValidKoreanPhone(v))
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
                    child: const Text('가입하고 인증 메일 받기'),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
