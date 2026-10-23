import 'package:flutter/material.dart';

import '../../../core/layout/app_dialog.dart';
import 'theme_mode_selector.dart';

/// 설정 대화상자: 화면 모드(테마)를 고른다.
Future<void> showSettingsDialog(BuildContext context) => showAppDialog<void>(
  context,
  maxWidth: 420,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('설정', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 16),
      const ThemeModeSelector(),
      const SizedBox(height: 20),
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
