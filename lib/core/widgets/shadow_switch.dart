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
    this.dividerBefore = const {},
    this.itemPadding = 12,
  });

  final List<T> values;
  final T selected;
  final ValueChanged<T> onChanged;
  final String Function(T value) labelOf;

  /// 이 번호의 항목 앞에 가는 세로 구분선: 항목들을 묶음으로 나눈다 (예: 0 · 1 · 2 | 3).
  final Set<int> dividerBefore;

  /// 항목 글자 좌우 여백. 항목이 많아 좁은 화면에 모자랄 때 줄인다.
  final double itemPadding;

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
                for (var i = 0; i < values.length; i++) ...[
                  if (dividerBefore.contains(i))
                    Container(
                      width: 1,
                      height: 18,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: palette.ink.withValues(alpha: 0.18),
                    ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(values[i]),
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
                              opacity: values[i] == selected ? 1 : 0,
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
                            padding: EdgeInsets.symmetric(
                              horizontal: itemPadding,
                              vertical: 6,
                            ),
                            child: Text(
                              labelOf(values[i]),
                              style: TextStyle(
                                fontSize: 14,
                                color: values[i] == selected
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
