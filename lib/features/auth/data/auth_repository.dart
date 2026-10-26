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
    required this.phone,
    required this.consentThirdParty,
    this.address = '',
    this.birthDate = '',
  });

  final String loginId;
  final String password;
  final String name;
  final String phone;

  /// 선택 입력. 비워 두면 저장하지 않는다.
  final String address;

  /// YYYY-MM-DD. 선택 입력.
  final String birthDate;

  /// 개인정보 제3자(소속 교회) 제공 동의.
  final bool consentThirdParty;
}

/// 로그인 / 가입. 교회 입장 승인은 교회 쪽에서 따로 처리한다.
///
/// 로그인은 ID + 비밀번호다. Firebase Auth는 계정마다 이메일이 필요하므로, 가입자의 이메일은
/// 받지 않고 ID로 만든 가상 이메일([LoginId.aliasEmail])을 계정에 쓴다. 이 값은 저장하거나 보여주지 않는다.
/// (예전에 실제 이메일로 가입한 계정은 loginIds/{ID} 문서에 남은 email로 로그인한다.)
class AuthRepository {
  AuthRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  /// 로그인·로그아웃뿐 아니라 표시 이름 변경(reload) 같은 계정 변경에도 값이 나온다.
  Stream<User?> userChanges() => _auth.userChanges();

  String get uid => _auth.currentUser!.uid;

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
      var email = LoginId.aliasEmail(id);
      if (!LoginId.isReserved(id)) {
        final snap = await _db.collection('loginIds').doc(id).get();
        if (!snap.exists) throw wrong;
        // 예전 계정만 실제 이메일이 남아 있다.
        email = snap.data()!['email'] as String? ?? email;
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

  /// 표시 이름을 바꾼다.
  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser!;
    await user.updateDisplayName(name);
    await user.reload();
  }

  // ---- 가입 ----

  /// ID로 가입한다. 계정을 만들고, ID 조회 문서와 회원 프로필을 저장한다. 이메일은 받지 않는다.
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
        email: LoginId.aliasEmail(id),
        password: data.password,
      );
      user = cred.user!;
    } on FirebaseAuthException catch (e) {
      if (e.code == "email-already-in-use") throw taken;
      throw AppException(_message(e));
    }

    try {
      await user.updateDisplayName(data.name.trim());
      final batch = _db.batch();
      batch.set(_db.collection('loginIds').doc(id), {'uid': user.uid});
      batch.set(_db.collection('users').doc(user.uid), {
        'loginId': id,
        'name': data.name.trim(),
        'phone': data.phone.trim(),
        if (data.address.trim().isNotEmpty) 'address': data.address.trim(),
        if (data.birthDate.trim().isNotEmpty)
          'birthDate': data.birthDate.trim(),
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
  }

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
    'weak-password' => '비밀번호는 6자 이상이어야 합니다.',
    'too-many-requests' => '요청이 너무 많아요. 잠시 후 다시 시도해 주세요.',
    'popup-closed-by-user' ||
    'canceled' ||
    'cancelled-popup-request' => '로그인이 취소되었습니다.',
    _ => e.message ?? e.code,
  };
}
