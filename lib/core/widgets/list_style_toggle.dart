import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/list_style_controller.dart';
import 'view_mode_toggle.dart';

/// 모임 일정의 보기 방식 버튼: 격자형은 알록달록(2열 카드), 리스트형은 심플(글 중심 목록).
/// 고른 값은 기기에 저장된다.
class ListStyleToggle extends StatelessWidget {
  const ListStyleToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.read(context).listStyle;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => ViewModeToggle(
        grid: controller.style == ListStyle.colorful,
        onChanged: (grid) =>
            controller.set(grid ? ListStyle.colorful : ListStyle.minimal),
      ),
    );
  }
}
