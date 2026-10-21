import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../church/view/church_hub.dart';
import 'login_page.dart';

/// 가입은 자유롭게, 교회 입장은 교회별 승인으로 나눈다.
/// 로그인 전에는 로그인 화면, 로그인 후에는 내 교회 메인 화면으로 이동한다.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AppScope.read(context).auth.authChanges(),
      builder: (context, auth) {
        if (auth.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = auth.data;
        if (user == null) return const LoginPage();
        return ChurchHub(key: ValueKey(user.uid));
      },
    );
  }
}
