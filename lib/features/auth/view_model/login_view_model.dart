import '../../../core/mvvm/view_model.dart';
import '../data/auth_repository.dart';

/// 로그인 화면: ID + 비밀번호, 또는 Google.
class LoginViewModel extends ViewModel {
  LoginViewModel(this._auth);

  final AuthRepository _auth;

  Future<bool> signIn(String loginId, String password) =>
      run(() => _auth.signInWithId(loginId, password));

  /// Google 팝업은 사용자가 닫을 수 있고 닫힘이 늦게 전달되므로, 기다리는 동안에도
  /// 로그인 버튼이 계속 눌리도록 busy를 켜지 않는다. 취소하면 오류 문구만 보이고 바로 다시 누를 수 있다.
  Future<bool> signInWithGoogle() =>
      run(_auth.signInWithGoogle, blocking: false);
}
