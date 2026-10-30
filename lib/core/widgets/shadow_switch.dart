import 'package:flutter/material.dart';

import '../theme.dart';

/// 큼직한 그림자가 있는 각진 전환 스위치: 옅은 바탕 위에 고른 항목이 흰 판으로 떠오른다.
/// 고른 항목의 판은 스위치 바탕보다 사방으로 조금 더 크고, 글자는 강조색 굵은 글씨다.
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

  /// 각진 모서리.
  static const _radius = 4.0;

  /// 고른 판이 바탕 밖으로 튀어나오는 정도.
  static const _grow = Offset(4, 6);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final shadow = dark ? Colors.black : const Color(0xFF2A2F6B);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.brand.withValues(alpha: dark ? 0.16 : 0.07),
        borderRadius: BorderRadius.circular(_radius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
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
                              color: palette.surface,
                              borderRadius: BorderRadius.circular(_radius),
                              boxShadow: [
                                BoxShadow(
                                  color: shadow.withValues(
                                    alpha: dark ? 0.55 : 0.2,
                                  ),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                                BoxShadow(
                                  color: shadow.withValues(
                                    alpha: dark ? 0.4 : 0.1,
                                  ),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          labelOf(v),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: v == selected
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: v == selected
                                ? palette.brand
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
    );
  }
}
