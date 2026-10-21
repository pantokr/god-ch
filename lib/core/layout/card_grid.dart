import 'dart:math';

import 'package:flutter/widgets.dart';

/// 컨테이너 폭에 따라 1~2열로 바뀌는 카드 그리드.
class CardGrid extends StatelessWidget {
  const CardGrid({
    super.key,
    required this.children,
    this.minColumnWidth = 380,
    this.gap = 16,
  });

  final List<Widget> children;
  final double minColumnWidth;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cols = max(
          1,
          min(2, ((width + gap) / (minColumnWidth + gap)).floor()),
        );
        final itemWidth = (width - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final c in children) SizedBox(width: itemWidth, child: c),
          ],
        );
      },
    );
  }
}
