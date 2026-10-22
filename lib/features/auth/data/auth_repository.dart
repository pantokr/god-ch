import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../core/app_exception.dart';
import 'login_id.dart';

/// 가입할 때 받는 정보.
class SignUpData {
  const SignUpData({
    required this.loginId,
    required this.password,
    required this.name,
    required this.email,
    required this.phone,
    required this.consentThirdParty,
  });

  final String loginId;
  final String password;
  final String name;
  final String email;
  final String phone;

  /// 개인정보 제3자(소속 교회) 제공 동의.
  final bool consentThirdParty;
}

/// 로그인 / 가입 / 이메일 인증. 교회 입장 승인은 교회 쪽에서 따로 처리한다.
///
/// 로그인은 ID + 비밀번호다. Firebase Auth는 이메일로 계정을 구분하므로,
/// 가입할 때 loginIds/{ID} 문서에 ID → 이메일 연결을 저장해 두고 로그인할 때 그것을 찾는다.
class AuthRepository {
  AuthRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  /// 로그인·로그아웃뿐 아니라 이메일 인증 확인(reload) 같은 계정 변경에도 값이 나온다.
  Stream<User?> userChanges() => _auth.userChanges();

  String get uid => _auth.currentUser!.uid;

  String get email => _auth.currentUser?.email ?? '';

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  String get displayName {
    final user = _auth.currentUser;
    if (user == null) return '';
    final name = (user.displayName ?? '').trim();
    if (name.isNotEmpty) return name;
    return (user.email ?? '이름 없음').split('@').first;
  }

  /// 앱 운영자 계정인가 (계정의 platformAdmin 클레임).
  Future<bool> hasOperatorClaim([User? user]) async {
    final target = user ?? _auth.currentUser;
    if (target == null) return false;
    final token = await target.getIdTokenResult();
    return token.claims?['platformAdmin'] == true;
  }

  // ---- 로그인 ----

  Future<void> signInWithId(String loginId, String password) => _guard(
    () async {
      final id = LoginId.normalize(loginId);
      const wrong = AppException('ID 또는 비밀번호가 올바르지 않습니다.');
      final String email;
      if (LoginId.isReserved(id)) {
        // 앱 운영자 같은 예약 ID는 조회 문서 없이 가상 이메일로 로그인한다.
        email = LoginId.aliasEmail(id);
      } else {
        final snap = await _db.collection('loginIds').doc(id).get();
        if (!snap.exists) throw wrong;
        email = snap.data()!['email'] as String;
      }
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    },
  );

  Future<void> signInWithGoogle() => _guard(() async {
    final provider = GoogleAuthProvider();
    if (kIsWeb) {
      await _auth.signInWithPopup(provider);
    } else {
      await _auth.signInWithProvider(provider);
    }
  });

  Future<void> signOut() => _auth.signOut();

  // ---- 가입 ----

  /// ID로 가입한다. 계정을 만들고, ID 조회 문서와 회원 프로필을 저장하고, 인증 메일을 보낸다.
  Future<void> signUp(SignUpData data) async {
    final id = LoginId.normalize(data.loginId);
    final idProblem = LoginId.validate(id);
    if (idProblem != null) throw AppException(idProblem);
    if (!data.consentThirdParty) {
      throw const AppException('개인정보 제3자 제공에 동의해야 가입할 수 있어요.');
    }

    const taken = AppException('이미 사용 중이거나 사용할 수 없는 ID입니다.');
    if ((await _db.collection('loginIds').doc(id).get()).exists) throw taken;

    final User user;
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: data.email.trim(),
        password: data.password,
      );
      user = cred.user!;
    } on FirebaseAuthException catch (e) {
      throw AppException(_message(e));
    }

    try {
      // 인증 메일이 실패해도 가입은 유지하고, 인증 화면에서 다시 보낼 수 있게 한다.
      await user.updateDisplayName(data.name.trim());
      final email = user.email!.toLowerCase();
      final batch = _db.batch();
      batch.set(_db.collection('loginIds').doc(id), {
        'uid': user.uid,
        'email': email,
      });
      batch.set(_db.collection('users').doc(user.uid), {
        'loginId': id,
        'name': data.name.trim(),
        'phone': data.phone.trim(),
        'email': email,
        'consentThirdParty': true,
        'consentAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
    } on FirebaseException catch (e) {
      // 동시에 같은 ID로 가입했거나 저장에 실패했다. 만든 계정을 되돌린다.
      await user.delete().catchError((_) {});
      if (e.code == 'permission-denied') throw taken;
      rethrow;
    }
    await sendVerificationEmail();
  }

  // ---- 이메일 인증 ----

  Future<void> sendVerificationEmail() =>
      _guard(() => _auth.currentUser!.sendEmailVerification());

  /// 메일의 인증 링크를 누른 뒤 최신 상태를 가져온다. userChanges에도 반영된다.
  Future<void> reloadUser() async => _auth.currentUser?.reload();

  /// Firebase 오류를 사용자에게 보여줄 한글 메시지로 바꾼다.
  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      throw AppException(_message(e));
    }
  }

  String _message(FirebaseAuthException e) => switch (e.code) {
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => 'ID 또는 비밀번호가 올바르지 않습니다.',
    'email-already-in-use' => '이미 가입된 이메일입니다.',
    'weak-password' => '비밀번호는 6자 이상이어야 합니다.',
    'invalid-email' => '이메일 형식이 올바르지 않습니다.',
    'too-many-requests' => '요청이 너무 많아요. 잠시 후 다시 시도해 주세요.',
    'popup-closed-by-user' || 'canceled' => '로그인이 취소되었습니다.',
    _ => e.message ?? e.code,
  };
}
