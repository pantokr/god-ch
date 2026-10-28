import '../../../core/icons.dart';

import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/back_navigation.dart';
import '../../../core/layout/app_dialog.dart';
import '../../../core/layout/profile_summary.dart';
import '../../../core/theme.dart';
import 'change_password_form.dart';
import 'my_affiliations_card.dart';
import 'profile_edit_dialog.dart';

/// 내 정보 페이지(프로필 사진을 누르면 열린다): 사진 · 이름 · 연락처 · 주소 · 생년월일을 고친다.
/// 비밀번호는 같은 화면의 "비밀번호 수정"을 눌렀을 때 팝업으로 바꾼다 (아이디로 가입한 계정만).
/// 앱 자체에 관한 것(화면 모드 · 앱 정보)은 설정 창에 있다.
class AccountPage extends StatelessWidget {
  const AccountPage({super.key, this.details = const []});

  /// 이름 밑에 덧붙일 항목 (예: 교회에서의 역할).
  final List<ProfileDetail> details;

  Future<void> _changePassword(BuildContext context) => showAppDialog<void>(
    context,
    maxWidth: 440,
    child: ChangePasswordForm(onDone: () => Navigator.of(context).pop()),
  );

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.read(context).auth;
    final palette = context.palette;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '뒤로',
          icon: const Icon(AppIcons.arrowLeft),
          onPressed: () => context.goBack(Routes.churches),
        ),
        title: const Text('내 정보'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: ProfileEditDialog(
                        name: auth.displayName,
                        details: details,
                        embedded: true,
                      ),
                    ),
                  ),
                  // 내가 속한 교회와 부서 (여러 개일 수 있다).
                  const MyAffiliationsCard(),
                  if (auth.hasPassword) ...[
                    const SizedBox(height: 20),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 20, 20, 20),
                        child: Row(
                          children: [
                            Icon(AppIcons.lock, color: palette.muted),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Text(
                                '비밀번호',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () => _changePassword(context),
                              child: const Text('비밀번호 수정'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
