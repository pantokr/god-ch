import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/app_exception.dart';
import '../../../data/models/user_profile.dart';
import '../../home/data/content_repository.dart';
import 'auth_repository.dart';

/// 회원 프로필(users/{uid}): 이름·전화번호·개인정보 제3자 제공 동의.
/// ID로 가입한 회원은 가입할 때 함께 만들어지고, Google로 가입한 회원은 첫 로그인 뒤에 만든다.
class ProfileRepository {
  ProfileRepository(FirebaseFirestore db, this._auth, this._contents)
    : _db = db,
      _users = db.collection('users');

  final FirebaseFirestore _db;
  final CollectionReference<Map<String, dynamic>> _users;
  final AuthRepository _auth;
  final ContentRepository _contents;

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

  /// 주소·생년월일(선택 정보)을 저장한다. 교회가 입장 때 필수로 요청한 정보를 채울 때 쓴다.
  /// 내 프로필 사진을 올리고 주소를 돌려준다. 저장(update)은 따로 한다.
  Future<String> uploadPhoto(String fileName, Uint8List bytes) =>
      _contents.uploadThumbnailTo('users/${_auth.uid}/avatar', bytes: bytes);

  Future<void> saveExtra({String? address, String? birthDate}) {
    final data = _extra(address, birthDate);
    if (data.isEmpty) return Future.value();
    return _users.doc(_auth.uid).update(data);
  }

  Map<String, Object> _extra(
    String? address,
    String? birthDate, [
    String? photoUrl,
  ]) {
    final a = address?.trim();
    final b = birthDate?.trim();
    if (a != null && a.length > 200) {
      throw const AppException('주소는 200자까지 쓸 수 있어요.');
    }
    if (b != null && b.isNotEmpty && DateTime.tryParse(b) == null) {
      throw const AppException('생년월일 형식이 올바르지 않아요.');
    }
    return {'address': ?a, 'birthDate': ?b, 'photoUrl': ?photoUrl?.trim()};
  }

  /// 이름·전화번호(와 선택 정보)를 고친다. 소속 교회의 내 교인 정보에도 같이 반영한다.
  /// 회원 프로필이 없는 계정(앱 운영자)은 표시 이름만 바뀐다.
  Future<void> update({
    required String name,
    required String phone,
    String? address,
    String? birthDate,
    String? photoUrl,
  }) async {
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
      final extra = _extra(address, birthDate, photoUrl);
      await _users.doc(_auth.uid).update({'name': n, 'phone': p, ...extra});
      final mine = await _db
          .collectionGroup('members')
          .where('uid', isEqualTo: _auth.uid)
          .get();
      final batch = _db.batch();
      for (final m in mine.docs) {
        batch.update(m.reference, {'name': n, 'phone': p, ...extra});
      }
      await batch.commit();
    }
    await _auth.updateDisplayName(n);
  }
}
