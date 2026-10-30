import 'package:flutter/material.dart';

import '../theme.dart';

/// 설정 묶음 같은 테두리 있는 면. 안에 [ListTile]류(체크 · 라디오 항목)를 놓아도 눌림 효과가 보이도록
/// 색을 장식 상자가 아니라 [Material] 바탕에 칠한다 (장식 상자의 색은 눌림 효과를 가린다).
class PanelSurface extends StatelessWidget {
  const PanelSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: palette.border),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
