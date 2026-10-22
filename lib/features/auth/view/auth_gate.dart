import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../data/models/user_profile.dart';
import '../../church/view/church_hub.dart';
import '../view_model/auth_gate_view_model.dart';
import 'email_verification_page.dart';
import 'login_page.dart';
import 'profile_completion_page.dart';

/// 로그인 상태에 따라 화면을 나눈다.
/// 로그인 전 → 로그인 / 이메일 인증 전 → 인증 안내 / 가입 정보 없음 → 정보 입력 / 그 밖 → 메인.
/// 앱 운영자 계정은 인증·정보 입력 단계를 건너뛴다.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<AuthGateViewModel>(
      create: (context) {
        final scope = AppScope.read(context);
        return AuthGateViewModel(scope.auth, scope.profiles);
      },
      builder: (context, vm) => StreamBuilder<User?>(
        stream: vm.users,
        builder: (context, auth) {
          if (auth.connectionState == ConnectionState.waiting) {
            return const _Loading();
          }
          final user = auth.data;
          if (user == null) return const LoginPage();

          return FutureBuilder<bool>(
            future: vm.isOperator(user),
            builder: (context, operator) {
              if (!operator.hasData) return const _Loading();
              if (operator.data!) return ChurchHub(key: ValueKey(user.uid));
              if (!user.emailVerified) return const EmailVerificationPage();

              return StreamBuilder<UserProfile?>(
                stream: vm.profile(user.uid),
                builder: (context, profile) {
                  if (profile.connectionState == ConnectionState.waiting) {
                    return const _Loading();
                  }
                  if (profile.data == null) {
                    return const ProfileCompletionPage();
                  }
                  return ChurchHub(key: ValueKey(user.uid));
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
