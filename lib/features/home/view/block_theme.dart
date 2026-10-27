import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../data/models/block_style.dart';
import '../../../data/models/page_layout.dart';

/// 색이 달라지는 구조가 쓰는 색 구성: 스타일([BlockStyle])과 팔레트 색에서 계산한다.
/// 라이트·다크 모드를 따라가서, 같은 선택이어도 모드에 맞게 보인다.
@immutable
class BlockTheme {
  const BlockTheme({
    required this.style,
    required this.accent,
    required this.accent2,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.text,
    required this.sub,
    required this.onAccent,
  });

  final BlockStyle style;

  /// 포인트색과 보조 포인트색 (그라데이션의 두 끝).
  final Color accent;
  final Color accent2;

  /// 카드 면과 그라데이션 끝색.
  final Color surface;
  final Color surface2;
  final Color border;

  /// 본문 글자 · 보조 글자 · 포인트색 위의 글자.
  final Color text;
  final Color sub;
  final Color onAccent;

  /// 이 스타일에서 일요일이나 강조 표시에 쓰는 빨강 계열.
  Color get sunday =>
      style == BlockStyle.neon ? accent2 : const Color(0xFFE5484D);

  LinearGradient get surfaceGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surface, surface2],
  );

  LinearGradient get accentGradient =>
      LinearGradient(colors: [accent, accent2]);

  /// 카드 한 장의 장식: 스타일마다 테두리 굵기와 그림자가 다르다.
  BoxDecoration card({double radius = AppRadius.card}) => BoxDecoration(
    gradient: surfaceGradient,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: border,
      width: style == BlockStyle.neon ? 1.2 : 1,
    ),
    boxShadow: switch (style) {
      BlockStyle.neon => [
        BoxShadow(
          color: accent.withValues(alpha: 0.28),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
      BlockStyle.pastel => [
        BoxShadow(
          color: accent.withValues(alpha: 0.16),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
      BlockStyle.simple => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    },
  );

  static Color _shift(Color c, double degrees, {double? lightness}) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withHue((hsl.hue + degrees) % 360)
        .withLightness(lightness ?? hsl.lightness)
        .toColor();
  }

  static Color _onColor(Color c) =>
      ThemeData.estimateBrightnessForColor(c) == Brightness.dark
      ? Colors.white
      : const Color(0xFF14121F);

  /// 블록이 고른 스타일·색으로 만든다.
  factory BlockTheme.of(BuildContext context, BlockConfig block) =>
      BlockTheme.from(context, block.style, block.paletteId);

  factory BlockTheme.from(
    BuildContext context,
    BlockStyle style,
    String paletteId,
  ) {
    final p = context.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final hue = BlockPalette.byId(paletteId).color;
    switch (style) {
      case BlockStyle.simple:
        // 어두운 모드에서는 포인트색을 밝게 올려 읽히게 한다.
        final accent = dark ? Color.lerp(hue, Colors.white, 0.3)! : hue;
        return BlockTheme(
          style: style,
          accent: accent,
          accent2: accent,
          surface: p.surface,
          surface2: p.surface,
          border: p.border,
          text: p.ink,
          sub: p.muted,
          onAccent: _onColor(accent),
        );
      case BlockStyle.pastel:
        final accent = dark ? Color.lerp(hue, Colors.white, 0.25)! : hue;
        return BlockTheme(
          style: style,
          accent: accent,
          accent2: _shift(accent, 28),
          surface: dark
              ? Color.alphaBlend(hue.withValues(alpha: 0.16), p.surface)
              : Color.lerp(Colors.white, hue, 0.10)!,
          surface2: dark
              ? Color.alphaBlend(hue.withValues(alpha: 0.26), p.surface)
              : Color.lerp(Colors.white, hue, 0.22)!,
          border: hue.withValues(alpha: dark ? 0.45 : 0.35),
          text: p.ink,
          sub: p.muted,
          onAccent: _onColor(accent),
        );
      case BlockStyle.neon:
        final accent = Color.lerp(hue, Colors.white, 0.3)!;
        final accent2 = _shift(accent, 55, lightness: 0.62);
        return BlockTheme(
          style: style,
          accent: accent,
          accent2: accent2,
          surface: Color.lerp(const Color(0xFF0B0B14), hue, 0.14)!,
          surface2: Color.lerp(const Color(0xFF0B0B14), hue, 0.34)!,
          border: accent.withValues(alpha: 0.75),
          text: Color.lerp(Colors.white, hue, 0.06)!,
          sub: Color.lerp(hue, Colors.white, 0.65)!,
          onAccent: _onColor(accent),
        );
    }
  }
}
