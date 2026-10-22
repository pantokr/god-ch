import 'dart:async';

import '../../../core/mvvm/view_model.dart';
import '../data/auth_repository.dart';

/// 이메일 인증 대기 화면. 메일의 링크를 누르면 몇 초 안에 자동으로 다음 화면으로 넘어간다.
class EmailVerificationViewModel extends ViewModel {
  EmailVerificationViewModel(this._auth) {
    _timer = Timer.periodic(_pollInterval, (_) => _auth.reloadUser());
  }

  static const _pollInterval = Duration(seconds: 3);

  final AuthRepository _auth;
  late final Timer _timer;
  bool _resent = false;

  String get email => _auth.email;

  /// 인증 메일을 다시 보냈는가 (보낸 직후 안내 문구용).
  bool get resent => _resent;

  Future<void> resend() async {
    final ok = await run(_auth.sendVerificationEmail);
    _resent = ok;
    notifyListeners();
  }

  /// 인증 링크를 이미 눌렀다면 바로 확인한다.
  Future<void> check() => run(_auth.reloadUser);

  Future<void> signOut() => _auth.signOut();

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
