import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/layout/profile_summary.dart';
import 'change_password_form.dart';
import 'profile_edit_dialog.dart';

/// 프로필(오른쪽 띠의 프로필 사진)을 누르면 열리는 창: **나에 관한 것**만 모았다.
/// 내 정보(사진 · 이름 · 연락처 · 주소 · 생년월일)와 비밀번호(아이디로 가입한 계정만).
/// 앱 자체에 관한 것(화면 모드 · 앱 정보)은 설정 창에 있다.
Future<void> showAccountDialog(
  BuildContext context, {
  required String name,
  List<ProfileDetail> details = const [],
}) => showDialog<void>(
  context: context,
  builder: (_) => Dialog(
    insetPadding: const EdgeInsets.all(16),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460, maxHeight: 640),
      child: _ProfilePanel(name: name, details: details),
    ),
  ),
);

enum _ProfileTab {
  info('내 정보'),
  password('비밀번호');

  const _ProfileTab(this.label);

  final String label;
}

class _ProfilePanel extends StatefulWidget {
  const _ProfilePanel({required this.name, required this.details});

  final String name;
  final List<ProfileDetail> details;

  @override
  State<_ProfilePanel> createState() => _ProfilePanelState();
}

class _ProfilePanelState extends State<_ProfilePanel> {
  _ProfileTab _tab = _ProfileTab.info;

  @override
  Widget build(BuildContext context) {
    // 비밀번호는 아이디/비밀번호로 가입한 계정만 바꿀 수 있다.
    final hasPassword = AppScope.read(context).auth.hasPassword;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 8, 0),
          child: Row(
            children: [
              if (hasPassword)
                Expanded(
                  child: SegmentedButton<_ProfileTab>(
                    showSelectedIcon: false,
                    segments: [
                      for (final t in _ProfileTab.values)
                        ButtonSegment(value: t, label: Text(t.label)),
                    ],
                    selected: {_tab},
                    onSelectionChanged: (v) => setState(() => _tab = v.first),
                  ),
                )
              else
                const Spacer(),
              IconButton(
                tooltip: '닫기',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: switch (_tab) {
              _ProfileTab.info => ProfileEditDialog(
                name: widget.name,
                details: widget.details,
                embedded: true,
              ),
              _ProfileTab.password => const ChangePasswordForm(),
            },
          ),
        ),
      ],
    );
  }
}
