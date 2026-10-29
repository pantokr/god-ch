import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 목록 화면의 모양: 알록달록(색이 있는 카드) 또는 심플 미니멀(글 중심 목록).
/// 기도제목 · 모임 · 성경이 함께 따르고, 고른 값은 이 기기에 저장되어 다음 실행에도 유지된다.
enum ListStyle {
  colorful('알록달록'),
  minimal('심플');

  const ListStyle(this.label);

  final String label;
}

class ListStyleController extends ChangeNotifier {
  ListStyleController(this._prefs) : _style = _read(_prefs);

  static const _key = 'list_style';

  /// 저장소를 쓸 수 없는 환경에서는 null이고, 그때는 저장하지 않는다.
  final SharedPreferences? _prefs;
  ListStyle _style;

  ListStyle get style => _style;

  static ListStyle _read(SharedPreferences? prefs) {
    final saved = prefs?.getString(_key);
    return ListStyle.values.firstWhere(
      (s) => s.name == saved,
      orElse: () => ListStyle.colorful,
    );
  }

  static Future<ListStyleController> load() async {
    try {
      return ListStyleController(await SharedPreferences.getInstance());
    } catch (_) {
      return ListStyleController(null);
    }
  }

  void set(ListStyle style) {
    if (_style == style) return;
    _style = style;
    notifyListeners();
    _prefs?.setString(_key, style.name);
  }
}
