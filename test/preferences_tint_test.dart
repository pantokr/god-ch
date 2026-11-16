import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:god_ch/app/preferences_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('중보기도와 말씀묵상은 같은 카드 색을 쓴다', () async {
    SharedPreferences.setMockInitialValues({'tint_bible': 'mint'});
    final prefs = await PreferencesController.load();
    // 예전에 말씀묵상에서 고른 색이 이어지고, 중보기도도 같은 색이다.
    expect(prefs.tintOf('bible'), ScreenTint.mint);
    expect(prefs.tintOf('prayer'), ScreenTint.mint);

    prefs.setTint('prayer', ScreenTint.sky);
    expect(prefs.tintOf('bible'), ScreenTint.sky);
    expect(prefs.tintOf('prayer'), ScreenTint.sky);
  });

  test('어두운 모드의 카드 색은 남색 바탕에 묻히도록 어둡고 푸른 기운이 있다', () {
    for (final t in ScreenTint.values) {
      final c = t.colorFor(Brightness.dark);
      if (c == null) continue;
      // 라이트 모드 색과 달리 아주 어둡다 (밝기 0.2 미만).
      expect(HSLColor.fromColor(c).lightness, lessThan(0.2), reason: t.name);
    }
  });

  test('중보기도와 말씀묵상은 같은 글씨 크기를 쓴다', () async {
    SharedPreferences.setMockInitialValues({'size_bible': 'large'});
    final prefs = await PreferencesController.load();
    expect(prefs.sizeOf('prayer'), TextSize.large);
    expect(prefs.sizeOf('bible'), TextSize.large);

    prefs.setSize('prayer', TextSize.small);
    expect(prefs.sizeOf('bible'), TextSize.small);
  });
}
