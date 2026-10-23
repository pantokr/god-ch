import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 화면 모드(시스템 / 라이트 / 다크). 고른 값은 이 기기에 저장되어 다음 실행에도 유지된다.
/// 기본은 시스템 설정을 따른다.
class ThemeModeController extends ChangeNotifier {
  ThemeModeController(this._prefs) : _mode = _read(_prefs);

  static const _key = 'theme_mode';

  /// 저장소를 쓸 수 없는 환경(개인정보 보호 모드 등)에서는 null이고, 그때는 저장하지 않는다.
  final SharedPreferences? _prefs;
  ThemeMode _mode;

  ThemeMode get mode => _mode;

  static ThemeMode _read(SharedPreferences? prefs) {
    final saved = prefs?.getString(_key);
    return ThemeMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => ThemeMode.system,
    );
  }

  /// 저장소를 불러와 컨트롤러를 만든다. 불러오지 못해도 앱은 시스템 모드로 계속 동작한다.
  static Future<ThemeModeController> load() async {
    try {
      return ThemeModeController(await SharedPreferences.getInstance());
    } catch (_) {
      return ThemeModeController(null);
    }
  }

  void setMode(ThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    _prefs?.setString(_key, mode.name);
  }
}
