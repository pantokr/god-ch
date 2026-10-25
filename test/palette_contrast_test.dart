import 'dart:math';

import 'package:god_ch/core/theme.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 상대 휘도.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

/// WCAG 대비. 일반 글자는 4.5 이상이 권장이다.
double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

void main() {
  const palettes = {'라이트': AppPalette.light, '다크': AppPalette.dark};

  for (final entry in palettes.entries) {
    final p = entry.value;
    group('${entry.key} 팔레트', () {
      test('본문 글자는 배경과 카드 위에서 읽기 쉽다', () {
        expect(_contrast(p.ink, p.bg), greaterThanOrEqualTo(7));
        expect(_contrast(p.ink, p.surface), greaterThanOrEqualTo(7));
      });

      test('보조 글자도 배경과 카드 위에서 기준을 넘는다', () {
        expect(_contrast(p.muted, p.bg), greaterThanOrEqualTo(4.5));
        expect(_contrast(p.muted, p.surface), greaterThanOrEqualTo(4.5));
      });

      test('포인트 색은 글자·아이콘으로 쓸 때 읽히고, 버튼 위 글자도 읽힌다', () {
        expect(_contrast(p.brand, p.bg), greaterThanOrEqualTo(4.5));
        expect(_contrast(p.brand, p.surface), greaterThanOrEqualTo(4.5));
        expect(_contrast(p.onBrand, p.brand), greaterThanOrEqualTo(4.5));
        expect(_contrast(p.accent, p.surface), greaterThanOrEqualTo(3));
      });

      test('테두리는 배경과 구분되지만 너무 튀지 않는다', () {
        final ratio = _contrast(p.border, p.bg);
        expect(ratio, greaterThan(1.05));
        expect(ratio, lessThan(3));
      });
    });
  }

  test('두 팔레트 사이를 부드럽게 섞을 수 있다 (화면 모드 전환 애니메이션)', () {
    final mid = AppPalette.light.lerp(AppPalette.dark, 0.5);
    expect(mid.bg, isNot(AppPalette.light.bg));
    expect(mid.bg, isNot(AppPalette.dark.bg));
    expect(AppPalette.light.lerp(AppPalette.dark, 0).bg, AppPalette.light.bg);
    expect(AppPalette.light.lerp(AppPalette.dark, 1).bg, AppPalette.dark.bg);
  });
}
