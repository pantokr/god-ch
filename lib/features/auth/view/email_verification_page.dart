import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../view_model/email_verification_view_model.dart';

/// 이메일 인증을 기다리는 화면. 인증 링크를 누르면 자동으로 다음 화면으로 넘어간다.
class EmailVerificationPage extends StatelessWidget {
  const EmailVerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ViewModelBuilder<EmailVerificationViewModel>(
      create: (context) =>
          EmailVerificationViewModel(AppScope.read(context).auth),
      builder: (context, vm) => Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.mark_email_unread_outlined,
                        size: 48,
                        color: context.palette.brand,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '이메일을 인증해 주세요',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${vm.email}\n주소로 보낸 인증 메일의 링크를 눌러 주세요.\n인증이 끝나면 자동으로 넘어가요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.palette.muted),
                      ),
                      if (vm.resent) ...[
                        const SizedBox(height: 12),
                        Text(
                          '인증 메일을 다시 보냈어요.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: context.palette.brand),
                        ),
                      ],
                      if (vm.error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          vm.error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: vm.busy ? null : vm.check,
                        child: const Text('인증했어요'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: vm.busy ? null : vm.resend,
                        child: const Text('인증 메일 다시 보내기'),
                      ),
                      TextButton(
                        onPressed: vm.signOut,
                        child: const Text('로그아웃'),
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
  }
}
