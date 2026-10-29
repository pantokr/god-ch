import '../icons.dart';

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/list_style_controller.dart';
import '../theme.dart';

/// 목록 모양을 고르는 작은 스위치: 알록달록(색이 있는 카드) / 심플(글 중심 목록).
/// 고른 값은 기도제목 · 모임 · 성경이 함께 따른다.
class ListStyleToggle extends StatelessWidget {
  const ListStyleToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.read(context).listStyle;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final palette = context.palette;
        Widget button(ListStyle style, IconData icon) {
          final on = controller.style == style;
          return Tooltip(
            message: style.label,
            child: InkResponse(
              onTap: () => controller.set(style),
              radius: 22,
              child: Container(
                width: 34,
                height: 30,
                decoration: BoxDecoration(
                  color: on ? palette.brand : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: on ? palette.onBrand : palette.muted,
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: palette.surface.withValues(alpha: 0.85),
              border: Border.all(color: palette.border),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  button(ListStyle.colorful, AppIcons.colorful),
                  button(ListStyle.minimal, AppIcons.listView),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
