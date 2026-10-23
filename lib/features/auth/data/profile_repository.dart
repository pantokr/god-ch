import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/app_exception.dart';
import '../../../data/models/user_profile.dart';
import 'auth_repository.dart';

/// 회원 프로필(users/{uid}): 이름·전화번호·개인정보 제3자 제공 동의.
/// ID로 가입한 회원은 가입할 때 함께 만들어지고, Google로 가입한 회원은 첫 로그인 뒤에 만든다.
class ProfileRepository {
  ProfileRepository(FirebaseFirestore db, this._auth)
    : _db = db,
      _users = db.collection('users');

  final FirebaseFirestore _db;
  final CollectionReference<Map<String, dynamic>> _users;
  final AuthRepository _auth;

  Stream<UserProfile?> profile(String uid) => _users
      .doc(uid)
      .snapshots()
      .map((s) => s.exists ? UserProfile.fromDoc(s) : null);

  Future<UserProfile?> current() async {
    final snap = await _users.doc(_auth.uid).get();
    return snap.exists ? UserProfile.fromDoc(snap) : null;
  }

  /// 내 프로필이 없으면 가입에 필요한 정보를 입력하도록 돌려보낸다.
  Future<UserProfile> requireCurrent() async {
    final profile = await current();
    if (profile == null) throw const AppException('회원 정보를 먼저 입력해 주세요.');
    return profile;
  }

  /// Google 가입자의 프로필을 만든다. 제3자 제공에 동의해야만 만들 수 있다.
  Future<void> createForSocial({
    required String name,
    required String phone,
    required bool consentThirdParty,
  }) {
    if (!consentThirdParty) {
      throw const AppException('개인정보 제3자 제공에 동의해야 가입할 수 있어요.');
    }
    return _users.doc(_auth.uid).set({
      'name': name.trim(),
      'phone': phone.trim(),
      'consentThirdParty': true,
      'consentAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 이름·전화번호를 고친다. 소속 교회의 내 교인 정보에도 같이 반영한다.
  /// 회원 프로필이 없는 계정(앱 운영자)은 표시 이름만 바뀐다.
  Future<void> update({required String name, required String phone}) async {
    final n = name.trim();
    final p = phone.trim();
    if (n.isEmpty || n.length > 30) {
      throw const AppException('이름은 1~30자로 입력해 주세요.');
    }
    final hasProfile = (await _users.doc(_auth.uid).get()).exists;
    if (hasProfile && (p.length < 8 || p.length > 20)) {
      throw const AppException('전화번호를 8~20자로 입력해 주세요.');
    }
    if (hasProfile) {
      await _users.doc(_auth.uid).update({'name': n, 'phone': p});
      final mine = await _db
          .collectionGroup('members')
          .where('uid', isEqualTo: _auth.uid)
          .get();
      final batch = _db.batch();
      for (final m in mine.docs) {
        batch.update(m.reference, {'name': n, 'phone': p});
      }
      await batch.commit();
    }
    await _auth.updateDisplayName(n);
  }
}
