import 'dart:ui' show Brightness, Color;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/bible_reference.dart' as bible;

/// 글씨 크기 단계. [factor]가 앱 기본 확대 배율(폰 · 와이드)에 곱해진다.
enum TextSize {
  small('작게', 0.92),
  normal('보통', 1.0),
  large('크게', 1.12);

  const TextSize(this.label, this.factor);

  final String label;
  final double factor;
}

/// 말씀묵상 본문 카드의 디자인.
enum DevotionDesign {
  paper('종이'),
  simple('심플'),
  quote('인용');

  const DevotionDesign(this.label);

  final String label;
}

/// 중보기도 · 말씀묵상 화면의 바탕 색조. [none]은 앱 기본 바탕이다.
enum ScreenTint {
  none('기본', null, null),
  sand('모래', Color(0xFFF1E8D6), Color(0xFF2A2520)),
  mint('민트', Color(0xFFE3F1EA), Color(0xFF1F2A26)),
  sky('하늘', Color(0xFFE2EEF8), Color(0xFF1E2630)),
  rose('분홍', Color(0xFFF8E6E8), Color(0xFF2E2224)),
  lavender('라벤더', Color(0xFFEBE6F6), Color(0xFF26222F)),
  gray('회색', Color(0xFFE9E9EC), Color(0xFF222226));

  const ScreenTint(this.label, this._light, this._dark);

  final String label;
  final Color? _light;
  final Color? _dark;

  /// 밝은 · 어두운 화면에서의 바탕색 (기본이면 null).
  Color? colorFor(Brightness b) => b == Brightness.dark ? _dark : _light;
}

/// 개인 설정: 이 기기에서만 쓰고 저장되는 보기 취향 (글씨 크기 · 본문 글꼴 · 중보기도 화면 색 · 책 이름 표기 · 절 번호 · 신규 표시).
/// 저장소를 쓸 수 없는 환경에서는 저장하지 않고 이번 실행 동안만 유지한다.
class PreferencesController extends ChangeNotifier {
  PreferencesController(this._prefs) {
    _syncGlobals();
  }

  final SharedPreferences? _prefs;

  static Future<PreferencesController> load() async {
    try {
      return PreferencesController(await SharedPreferences.getInstance());
    } catch (_) {
      return PreferencesController(null);
    }
  }

  // 화면마다 따로 읽는 값(구절 표기)은 전역 값에 옮겨 둔다.
  void _syncGlobals() {
    bible.useBookAbbreviation = abbreviateBooks;
  }

  void _save() {
    _syncGlobals();
    notifyListeners();
  }

  // ---- 글씨 ----
  TextSize get textSize {
    final saved = _prefs?.getString('text_size');
    return TextSize.values.firstWhere(
      (s) => s.name == saved,
      orElse: () => TextSize.normal,
    );
  }

  void setTextSize(TextSize v) {
    _prefs?.setString('text_size', v.name);
    _save();
  }

  // ---- 화면별 보기 (중보기도 · 말씀묵상 각각) ----
  /// 화면 이름: `prayer` · `bible`.
  ScreenTint tintOf(String screen) {
    final saved = _prefs?.getString('tint_$screen');
    return ScreenTint.values.firstWhere(
      (s) => s.name == saved,
      orElse: () => ScreenTint.none,
    );
  }

  void setTint(String screen, ScreenTint v) {
    _prefs?.setString('tint_$screen', v.name);
    _save();
  }

  /// 그 화면만의 글씨 크기 (전체 글씨 크기에 더해 곱해진다).
  TextSize sizeOf(String screen) {
    final saved = _prefs?.getString('size_$screen');
    return TextSize.values.firstWhere(
      (s) => s.name == saved,
      orElse: () => TextSize.normal,
    );
  }

  void setSize(String screen, TextSize v) {
    _prefs?.setString('size_$screen', v.name);
    _save();
  }

  /// 그 화면의 글꼴.

  // ---- 말씀묵상 ----
  /// 구절 제목의 책 이름을 줄임말로 보는가 (아니면 전체 이름).
  bool get abbreviateBooks => _prefs?.getBool('abbreviate_books') ?? false;

  void setAbbreviateBooks(bool v) {
    _prefs?.setBool('abbreviate_books', v);
    _save();
  }

  /// 말씀 본문에 절 번호를 보이는가.
  bool get showVerseNumbers => _prefs?.getBool('verse_numbers') ?? true;

  void setShowVerseNumbers(bool v) {
    _prefs?.setBool('verse_numbers', v);
    _save();
  }

  /// 말씀묵상 본문 카드의 디자인 (기본: 종이).
  DevotionDesign get devotionDesign {
    final saved = _prefs?.getString('design_bible');
    return DevotionDesign.values.firstWhere(
      (d) => d.name == saved,
      orElse: () => DevotionDesign.paper,
    );
  }

  void setDevotionDesign(DevotionDesign v) {
    _prefs?.setString('design_bible', v.name);
    _save();
  }

  // ---- 이 기기에서 연 글 ----
  /// 글을 열어 본 적이 있는가 (서버의 읽음 기록과 별개로 이 기기에 남긴다: 신규 표시가 바로 사라지게 한다).
  bool seen(String key) => _seen.contains(key);

  late final Set<String> _seen = {...?_prefs?.getStringList('seen_posts')};

  /// 글을 열었다고 기록한다. 오래된 기록은 300개까지만 남긴다.
  void markSeen(String key) {
    if (!_seen.add(key)) return;
    final list = _seen.toList();
    if (list.length > 300) {
      _seen
        ..clear()
        ..addAll(list.skip(list.length - 300));
    }
    _prefs?.setStringList('seen_posts', _seen.toList());
    _notifyAfterBuild();
  }

  /// 글 화면이 만들어지는 중(build)에 불리면 바로 알리지 않고 그 프레임이 끝난 뒤에 알린다.
  /// build 중에 듣는 쪽(목록 · 앱 틀)을 다시 그리게 하면 "build 중 setState" 오류가 나기 때문이다.
  void _notifyAfterBuild() {
    final binding = SchedulerBinding.instance;
    if (binding.schedulerPhase == SchedulerPhase.idle) {
      notifyListeners();
    } else {
      binding.addPostFrameCallback((_) => notifyListeners());
    }
  }

  // ---- 화면별 기본 보기 · 정렬 (화면 안의 버튼에서 이미 고르므로 개인 설정 화면에는 두지 않는다) ----
  bool gridOf(String screen) => _prefs?.getBool('grid_$screen') ?? false;
  String? sortOf(String screen) => _prefs?.getString('sort_$screen');
}
