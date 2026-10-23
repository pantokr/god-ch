import '../../../core/mvvm/view_model.dart';
import '../data/auth_repository.dart';

/// 상단 바의 계정 정보(이름·이메일)와 로그아웃. 여러 화면의 틀이 함께 쓴다.
class AccountViewModel extends ViewModel {
  AccountViewModel(this._auth);

  final AuthRepository _auth;

  String get userName => _auth.displayName;

  Future<void> signOut() => _auth.signOut();
}
