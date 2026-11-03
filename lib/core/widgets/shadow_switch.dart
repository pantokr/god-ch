import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// 테두리만으로 이루어진 알약 전환 스위치: 옅은 회색 바탕 안에서, 고른 항목만 흰 판에 진한 테두리로 둘러싼다.
/// 항목은 같은 폭으로 나뉜다.
class ShadowSwitch<T> extends StatelessWidget {
  const ShadowSwitch({
    super.key,
    required this.values,
    required this.selected,
    required this.onChanged,
    required this.labelOf,
  });

  final List<T> values;
  final T selected;
  final ValueChanged<T> onChanged;
  final String Function(T value) labelOf;

  /// 알약 모양의 둥근 모서리.
  static const _radius = 999.0;

  /// 항목 하나의 최소 너비. 가장 긴 글자에 맞춰 더 넓어진다 (스위치는 항목 수만큼만 폭을 쓴다).
  static const _itemWidth = 92.0;

  /// 고른 판이 바탕 밖으로 튀어나오는 정도.
  static const _grow = Offset(4, 4);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: ConstrainedBox(
        // 글자가 길면 항목이 넓어져 답답하지 않게 한다 (글자 한 자 약 15, 좌우 여백 포함).
        constraints: BoxConstraints(
          maxWidth:
              math.max(
                _itemWidth,
                (values.map((v) => labelOf(v).length).reduce(math.max) * 15 +
                        40)
                    .toDouble(),
              ) *
              values.length,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: palette.ink.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(_radius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                for (final v in values)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(v),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            left: -_grow.dx,
                            right: -_grow.dx,
                            top: -_grow.dy,
                            bottom: -_grow.dy,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 180),
                              opacity: v == selected ? 1 : 0,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  // 다크 모드에서는 바탕보다 밝은 판이어야 선택이 보인다.
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Color.alphaBlend(
                                          palette.ink.withValues(alpha: 0.22),
                                          palette.surface,
                                        )
                                      : palette.surface,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  borderRadius: BorderRadius.circular(_radius),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Text(
                              labelOf(v),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: v == selected
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                color: v == selected
                                    ? palette.ink
                                    : palette.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
