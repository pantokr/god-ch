import 'package:flutter/material.dart';

import '../../../core/widgets/labeled_field.dart';

import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/formatters/korean_phone.dart';
import '../../../core/layout/sub_page.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/blur_validated_field.dart';
import '../data/auth_repository.dart';
import '../data/login_id.dart';
import '../data/password_rule.dart';
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
      // 다른 화면들처럼 상단 탭(뒤로가기 + 제목) 아래에 묶음별 카드를 쌓는다.
      builder: (context, vm) => SubPage(
        title: '',
        barTitle: '회원가입',
        fallbackLocation: Routes.login,
        maxWidth: 520,
        inset: true,
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FieldGroup(
                title: '로그인 정보',
                children: [
                  LabeledField(
                    label: '아이디',
                    required: true,
                    child: BlurValidatedField(
                      controller: _loginId,
                      autocorrect: false,
                      maxLength: 20,
                      decoration: const InputDecoration(),
                      validator: (v) => LoginId.validate(v ?? ''),
                    ),
                  ),
                  LabeledField(
                    label: '비밀번호',
                    required: true,
                    child: BlurValidatedField(
                      controller: _password,
                      onChanged: (_) => setState(() {}),
                      obscureText: true,
                      decoration: const InputDecoration(suffixText: '8자 이상'),
                      validator: PasswordRule.validate,
                    ),
                  ),
                  LabeledField(
                    label: '비밀번호 확인',
                    required: true,
                    child: BlurValidatedField(
                      controller: _passwordConfirm,
                      obscureText: true,
                      decoration: const InputDecoration(),
                      validator: (v) => PasswordRule.confirm(v, _password.text),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _FieldGroup(
                title: '기본 정보',
                children: [
                  LabeledField(
                    label: '이름',
                    required: true,
                    child: BlurValidatedField(
                      controller: _name,
                      maxLength: 30,
                      decoration: const InputDecoration(),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? '이름을 입력해 주세요'
                          : null,
                    ),
                  ),
                  LabeledField(
                    label: '전화번호',
                    required: true,
                    child: BlurValidatedField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      inputFormatters: const [KoreanPhoneFormatter()],
                      decoration: const InputDecoration(
                        hintText: '010-1234-5678',
                      ),
                      validator: (v) => (v == null || !isValidKoreanPhone(v))
                          ? '전화번호 형식이 올바르지 않아요'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _FieldGroup(
                title: '추가 정보 (선택)',
                children: [
                  ProfileExtraFields(address: _address, birthDate: _birthDate),
                ],
              ),
              const SizedBox(height: 16),
              ConsentCheckbox(
                value: _consent,
                onChanged: (v) => setState(() => _consent = v),
              ),
              if (vm.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  vm.error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: (vm.busy || !_consent) ? null : () => _submit(vm),
                child: const Text('가입하기'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: vm.busy
                    ? null
                    : () => context.canPop()
                          ? context.pop()
                          : context.go(Routes.login),
                child: const Text('로그인'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 가입 화면의 입력란 묶음: 제목 아래에 입력란을 쌓은 카드 한 장.
class _FieldGroup extends StatelessWidget {
  const _FieldGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) AppField.spacer,
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}
