import 'package:flutter/material.dart';

import '../theme.dart';
import 'app_dialog.dart';

/// 프로필에 덧붙여 보여줄 항목 한 줄 (예: 교회 / 역할).
class ProfileDetail {
  const ProfileDetail(this.label, this.value);

  final String label;
  final String value;
}

/// 이름·이메일과 추가 항목을 보여주는 내 정보 내용.
/// 데스크톱의 "내 정보" 대화상자와 모바일의 내 정보 탭이 함께 쓴다.
class ProfileSummary extends StatelessWidget {
  const ProfileSummary({
    super.key,
    required this.name,
    required this.email,
    this.details = const [],
  });

  final String name;
  final String email;
  final List<ProfileDetail> details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.brand.withValues(alpha: 0.12),
              child: Text(
                name.isEmpty ? '?' : name.characters.first,
                style: const TextStyle(
                  fontSize: 22,
                  color: AppColors.brand,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (email.isNotEmpty)
                    Text(email, style: const TextStyle(color: AppColors.muted)),
                ],
              ),
            ),
          ],
        ),
        if (details.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Divider(),
          for (final d in details)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    child: Text(
                      d.label,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ),
                  Expanded(child: Text(d.value)),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

/// 데스크톱에서 "내 정보" 버튼을 눌렀을 때 뜨는 대화상자.
Future<void> showProfileDialog(
  BuildContext context, {
  required String name,
  required String email,
  List<ProfileDetail> details = const [],
}) => showAppDialog<void>(
  context,
  maxWidth: 420,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('내 정보', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 16),
      ProfileSummary(name: name, email: email, details: details),
      const SizedBox(height: 16),
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ),
    ],
  ),
);
