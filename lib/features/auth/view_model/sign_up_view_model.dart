import '../../../core/mvvm/view_model.dart';
import '../data/auth_repository.dart';

/// 회원가입: ID, 비밀번호, 이름, 이메일, 전화번호, 개인정보 제3자 제공 동의.
/// 가입하면 인증 메일이 발송되고, 이메일 인증을 마쳐야 앱을 쓸 수 있다.
class SignUpViewModel extends ViewModel {
  SignUpViewModel(this._auth);

  final AuthRepository _auth;

  /// 가입에 성공하면 true.
  Future<bool> submit(SignUpData data) => run(() => _auth.signUp(data));
}
