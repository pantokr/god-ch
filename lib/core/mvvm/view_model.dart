import 'package:flutter/foundation.dart';

import '../app_exception.dart';

/// 화면의 상태와 동작을 담는 ViewModel의 기반 클래스.
/// 진행 중 여부(busy)와 마지막 오류(error)를 [run]으로 한 번에 관리한다.
abstract class ViewModel extends ChangeNotifier {
  bool _busy = false;
  String? _error;
  bool _disposed = false;

  bool get busy => _busy;
  String? get error => _error;

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  /// [action]을 실행하면서 busy/error를 갱신한다. 성공하면 true.
  /// [blocking]이 false면 busy를 켜지 않는다 (사용자가 중간에 닫을 수 있는 팝업 로그인처럼,
  /// 끝나기를 기다리는 동안에도 버튼이 눌려야 하는 동작).
  Future<bool> run(
    Future<void> Function() action, {
    bool blocking = true,
  }) async {
    if (blocking) _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (e) {
      _error = e is AppException ? e.message : '$e';
      return false;
    } finally {
      if (blocking) _busy = false;
      notifyListeners();
    }
  }

  // 비동기 작업이 끝나기 전에 화면이 사라져도 오류가 나지 않게 한다.
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
