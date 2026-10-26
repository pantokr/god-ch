import '../../../core/mvvm/view_model.dart';
import '../data/auth_repository.dart';

/// 회원가입: ID, 비밀번호, 이름, 전화번호, 개인정보 제3자 제공 동의. 이메일은 받지 않는다.
class SignUpViewModel extends ViewModel {
  SignUpViewModel(this._auth);

  final AuthRepository _auth;

  /// 가입에 성공하면 true.
  Future<bool> submit(SignUpData data) => run(() => _auth.signUp(data));
}
