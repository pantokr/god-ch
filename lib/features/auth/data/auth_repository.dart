import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../core/app_exception.dart';

/// 로그인 / 가입. 가입은 자유롭고, 교회 입장 승인은 교회 쪽에서 따로 처리한다.
class AuthRepository {
  AuthRepository(this._auth);

  final FirebaseAuth _auth;

  Stream<User?> authChanges() => _auth.authStateChanges();

  String get uid => _auth.currentUser!.uid;

  String get email => _auth.currentUser?.email ?? '';

  String get displayName {
    final user = _auth.currentUser;
    if (user == null) return '';
    final name = (user.displayName ?? '').trim();
    if (name.isNotEmpty) return name;
    return (user.email ?? '이름 없음').split('@').first;
  }

  Future<void> signInWithEmail(String email, String password) => _guard(
    () async {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    },
  );

  Future<void> signUpWithEmail(String name, String email, String password) =>
      _guard(() async {
        final cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        await cred.user!.updateDisplayName(name);
      });

  Future<void> signInWithGoogle() => _guard(() async {
    final provider = GoogleAuthProvider();
    if (kIsWeb) {
      await _auth.signInWithPopup(provider);
    } else {
      await _auth.signInWithProvider(provider);
    }
  });

  Future<void> signOut() => _auth.signOut();

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
    'user-not-found' => '이메일 또는 비밀번호가 올바르지 않습니다.',
    'email-already-in-use' => '이미 가입된 이메일입니다.',
    'weak-password' => '비밀번호는 6자 이상이어야 합니다.',
    'invalid-email' => '이메일 형식이 올바르지 않습니다.',
    'popup-closed-by-user' || 'canceled' => '로그인이 취소되었습니다.',
    _ => e.message ?? e.code,
  };
}
