import '../../../core/mvvm/view_model.dart';
import '../data/auth_repository.dart';

/// 로그인 화면: ID + 비밀번호, 또는 Google.
class LoginViewModel extends ViewModel {
  LoginViewModel(this._auth);

  final AuthRepository _auth;

  Future<bool> signIn(String loginId, String password) =>
      run(() => _auth.signInWithId(loginId, password));

  Future<bool> signInWithGoogle() => run(_auth.signInWithGoogle);
}
