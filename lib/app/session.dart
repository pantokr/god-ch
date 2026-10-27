import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../data/models/user_profile.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/profile_repository.dart';
import '../features/church/data/church_request_repository.dart';

/// 로그인 뒤 어느 영역으로 보낼지를 정하는 상태.
enum SessionStatus {
  /// 로그인 여부나 권한을 확인하는 중.
  loading,

  /// 로그인하지 않음.
  signedOut,

  /// 가입 정보(이름·전화번호·동의)를 아직 입력하지 않음.
  needsProfile,

  /// 일반 회원.
  member,

  /// 앱 운영자.
  operator,
}

/// 로그인 상태를 지켜보다가 [status]가 바뀌면 알려 준다. 라우터가 이 값으로 화면을 나눈다.
/// 앱 운영자는 가입 정보 입력을 거치지 않는다.
class SessionNotifier extends ChangeNotifier {
  SessionNotifier(this._auth, this._profiles, this._requests) {
    _userSub = _auth.userChanges().listen(_onUser);
  }

  final AuthRepository _auth;
  final ProfileRepository _profiles;
  final ChurchRequestRepository _requests;

  late final StreamSubscription<User?> _userSub;
  StreamSubscription<UserProfile?>? _profileSub;

  /// 앱을 켤 때 스플래시가 적어도 이만큼은 보이도록, 첫 판단은 이 시간이 지난 뒤에 알린다.
  static const minSplash = Duration(seconds: 1);

  SessionStatus _status = SessionStatus.loading;
  final _started = DateTime.now();
  bool _splashDone = false;
  SessionStatus? _pending;
  Timer? _splashTimer;

  // 같은 계정의 토큰 갱신 등으로 값이 다시 나와도 화면이 깜빡이지 않게,
  // 계정이 실제로 바뀔 때만 다시 판단한다.
  String? _lastUid;
  int _generation = 0;

  SessionStatus get status => _status;

  Future<void> _onUser(User? user) async {
    if (user?.uid == _lastUid && _status != SessionStatus.loading) {
      return;
    }
    _lastUid = user?.uid;
    final generation = ++_generation;
    await _profileSub?.cancel();
    _profileSub = null;

    if (user == null) return _set(SessionStatus.signedOut);
    _set(SessionStatus.loading);

    final operator = await _isOperator();
    if (generation != _generation) return;
    if (operator) return _set(SessionStatus.operator);

    // 가입 정보가 생기면 자동으로 member가 된다.
    _profileSub = _profiles
        .profile(user.uid)
        .listen(
          (profile) {
            if (generation != _generation) return;
            _set(
              profile == null
                  ? SessionStatus.needsProfile
                  : SessionStatus.member,
            );
          },
          onError: (_) {
            if (generation == _generation) _set(SessionStatus.needsProfile);
          },
        );
  }

  Future<bool> _isOperator() async {
    try {
      return await _requests.isPlatformAdmin().first;
    } catch (_) {
      return false;
    }
  }

  void _set(SessionStatus status) {
    // 처음 켤 때만: 스플래시를 최소 시간 동안 보여 준 뒤 가장 최근 판단을 알린다.
    if (!_splashDone && _status == SessionStatus.loading) {
      final left = minSplash - DateTime.now().difference(_started);
      if (left > Duration.zero) {
        _pending = status;
        _splashTimer ??= Timer(left, () {
          _splashDone = true;
          final next = _pending;
          _pending = null;
          if (next != null) _set(next);
        });
        return;
      }
      _splashDone = true;
    }
    if (_status == status) return;
    _status = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    _userSub.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}
