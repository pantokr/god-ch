import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/mvvm/view_model.dart';
import '../../../data/models/user_profile.dart';
import '../data/auth_repository.dart';
import '../data/profile_repository.dart';

/// 로그인 뒤 어느 화면으로 보낼지 판단하는 데 필요한 정보를 모은다.
/// 같은 계정에 대해서는 Future/Stream을 한 번만 만들어 화면이 다시 그려져도 재조회하지 않는다.
class AuthGateViewModel extends ViewModel {
  AuthGateViewModel(this._auth, this._profiles) : users = _auth.userChanges();

  final AuthRepository _auth;
  final ProfileRepository _profiles;

  /// 로그인 상태와 계정 변경(이메일 인증 완료 등).
  final Stream<User?> users;

  final _operatorClaims = <String, Future<bool>>{};
  final _profileStreams = <String, Stream<UserProfile?>>{};

  /// 앱 운영자 계정인가. 운영자는 가입 정보 입력과 이메일 인증을 거치지 않는다.
  Future<bool> isOperator(User user) =>
      _operatorClaims[user.uid] ??= _auth.hasOperatorClaim(user);

  /// 가입 정보(프로필). 아직 없으면 null.
  Stream<UserProfile?> profile(String uid) =>
      _profileStreams[uid] ??= _profiles.profile(uid);
}
