import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/theme.dart';

/// 화면 모드를 고른다: 시스템 설정을 따르거나 라이트 / 다크로 고정한다.
class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.read(context).themeMode;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('화면 모드', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto_outlined, size: 18),
                label: Text('시스템'),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_outlined, size: 18),
                label: Text('라이트'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_outlined, size: 18),
                label: Text('다크'),
              ),
            ],
            selected: {controller.mode},
            onSelectionChanged: (s) => controller.setMode(s.first),
          ),
          const SizedBox(height: 6),
          Text(
            '시스템은 기기의 라이트/다크 설정을 따라요.',
            style: TextStyle(color: context.palette.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
