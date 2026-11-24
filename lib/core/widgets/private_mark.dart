import 'package:flutter/material.dart';

import '../icons.dart';
import '../theme.dart';

/// 비공개 글 표시: 인디고→코랄 그라데이션 동그라미 안의 굵은 자물쇠와 옅은 빛무리.
/// 밋밋한 회색 자물쇠 대신 한눈에 띄도록 색을 입힌다 (목록 · 상세 · 카드가 같은 모양을 쓴다).
/// [label]을 주면 오른쪽에 이름이 붙은 알약이 된다 (예: 교역자 전용).
class PrivateMark extends StatelessWidget {
  const PrivateMark({super.key, this.size = 22, this.label});

  /// 동그라미 지름.
  final double size;

  /// 알약으로 보일 때의 글자. 없으면 동그라미만 보인다.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final disc = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.brand, palette.accent],
        ),
        // 빛무리는 다크 모드에서 어색하게 번지므로 라이트에서만 둔다.
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: palette.brand.withValues(alpha: 0.35),
                  blurRadius: 6,
                  spreadRadius: 0.5,
                ),
              ],
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(AppIcons.lockFill, size: size * 0.55, color: Colors.white),
      ),
    );
    final text = label;
    if (text == null) return Semantics(label: '비공개', child: disc);
    return Container(
      padding: EdgeInsets.fromLTRB(4, 3, 10, 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        gradient: LinearGradient(
          colors: [
            palette.brand.withValues(alpha: dark ? 0.22 : 0.12),
            palette.accent.withValues(alpha: dark ? 0.18 : 0.1),
          ],
        ),
        border: Border.all(
          color: palette.brand.withValues(alpha: dark ? 0.4 : 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          disc,
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.3,
              color: dark ? palette.ink : palette.brand,
            ),
          ),
        ],
      ),
    );
  }
}
