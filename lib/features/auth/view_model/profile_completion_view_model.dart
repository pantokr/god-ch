import '../../../core/mvvm/view_model.dart';
import '../data/auth_repository.dart';
import '../data/profile_repository.dart';

/// Google로 처음 로그인한 회원의 가입 정보 입력: 이름, 전화번호, 개인정보 제3자 제공 동의.
class ProfileCompletionViewModel extends ViewModel {
  ProfileCompletionViewModel(this._profiles, this._auth);

  final ProfileRepository _profiles;
  final AuthRepository _auth;

  /// 이름 입력란의 기본값 (Google 계정 이름).
  String get suggestedName => _auth.displayName;

  Future<bool> submit({
    required String name,
    required String phone,
    required bool consent,
  }) => run(
    () => _profiles.createForSocial(
      name: name,
      phone: phone,
      consentThirdParty: consent,
    ),
  );

  Future<void> signOut() => _auth.signOut();
}
