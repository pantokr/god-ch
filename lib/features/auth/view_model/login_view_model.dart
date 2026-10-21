import '../../../core/mvvm/view_model.dart';
import '../data/auth_repository.dart';

/// 로그인 / 회원가입 화면의 상태와 동작.
class LoginViewModel extends ViewModel {
  LoginViewModel(this._auth);

  final AuthRepository _auth;

  bool _signUp = false;

  /// true면 회원가입 모드, false면 로그인 모드.
  bool get signUp => _signUp;

  void toggleMode() {
    _signUp = !_signUp;
    clearError();
    notifyListeners();
  }

  Future<void> submit({
    required String name,
    required String email,
    required String password,
  }) => run(
    () => _signUp
        ? _auth.signUpWithEmail(name, email, password)
        : _auth.signInWithEmail(email, password),
  );

  Future<void> signInWithGoogle() => run(_auth.signInWithGoogle);
}
