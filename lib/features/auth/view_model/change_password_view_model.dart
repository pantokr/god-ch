import '../../../core/app_exception.dart';
import '../../../core/mvvm/view_model.dart';
import '../data/auth_repository.dart';
import '../data/password_rule.dart';

/// 설정에서 비밀번호를 바꾼다.
class ChangePasswordViewModel extends ViewModel {
  ChangePasswordViewModel(this._auth);

  final AuthRepository _auth;

  Future<bool> change(String current, String next, String confirm) => run(() {
    if (current.isEmpty) throw const AppException('현재 비밀번호를 입력해 주세요.');
    final rule =
        PasswordRule.validate(next) ?? PasswordRule.confirm(confirm, next);
    if (rule != null) throw AppException(rule);
    if (next == current) {
      throw const AppException('현재 비밀번호와 다른 비밀번호를 입력해 주세요.');
    }
    return _auth.changePassword(current, next);
  });
}
