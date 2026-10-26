import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../view_model/login_view_model.dart';

/// ID + 비밀번호로 로그인하거나, Google로 계속한다.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 입력 컨트롤러는 화면(View)의 상태다. 로그인 동작은 ViewModel이 맡는다.
  final _form = GlobalKey<FormState>();
  final _loginId = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _loginId.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit(LoginViewModel vm) {
    if (!_form.currentState!.validate()) return;
    vm.signIn(_loginId.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<LoginViewModel>(
      create: (context) => LoginViewModel(AppScope.read(context).auth),
      builder: (context, vm) => Scaffold(
        // 화면 폭에 맞춰 늘어나지 않고, 가운데에 고정 폭 카드만 놓는다.
        body: Center(child: _buildCard(context, vm)),
      ),
    );
  }

  Widget _buildCard(BuildContext context, LoginViewModel vm) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Brand(),
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.panel),
                side: BorderSide(color: context.palette.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _form,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '로그인',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _loginId,
                        autofillHints: const [AutofillHints.username],
                        autocorrect: false,
                        decoration: const InputDecoration(labelText: '아이디'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? '아이디를 입력해 주세요'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        autofillHints: const [AutofillHints.password],
                        decoration: const InputDecoration(labelText: '비밀번호'),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? '비밀번호를 입력해 주세요' : null,
                        onFieldSubmitted: (_) => _submit(vm),
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
                        onPressed: vm.busy ? null : () => _submit(vm),
                        child: const Text('로그인'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: vm.busy ? null : vm.signInWithGoogle,
                        icon: const Icon(Icons.g_mobiledata, size: 28),
                        label: const Text('Google로 계속하기'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: vm.busy
                            ? null
                            : () => context.push(Routes.signUp),
                        child: const Text('계정이 없어요 · 회원가입'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 로그인 카드 위에 놓는 로고와 한 줄 소개.
class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.volunteer_activism, color: context.palette.brand, size: 40),
        SizedBox(height: 12),
        Text('같이', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        SizedBox(height: 6),
        Text(
          '서로의 기도제목을 조용히 나누는 공간',
          style: TextStyle(color: context.palette.muted),
        ),
      ],
    );
  }
}
