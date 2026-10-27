import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/app_exception.dart';
import '../../../data/firestore_paths.dart';
import '../../../data/models/church.dart';
import '../../../data/models/department.dart';
import '../../../data/models/member.dart';
import '../../../data/models/user_profile.dart';
import '../../auth/data/auth_repository.dart';
import '../../home/data/content_repository.dart';

/// 앱 운영자 패널의 데이터: 등록된 교회 목록과 직접 등록, 전체 회원.
/// 앱 운영자는 교회에 소속되지 않으므로 교회의 교인으로 등록되지 않는다.
/// (교회 생성 요청의 승인·거절은 [ChurchRequestRepository]가 맡는다.)
class ChurchRegistryRepository {
  ChurchRegistryRepository(FirebaseFirestore db, this._auth, this._contents)
    : _db = db,
      _paths = FirestorePaths(db);

  final FirebaseFirestore _db;
  final FirestorePaths _paths;
  final AuthRepository _auth;
  final ContentRepository _contents;

  /// 등록된 모든 교회 (앱 운영자 전용).
  Stream<List<Church>> churches() => _paths.churches
      .orderBy('createdAt')
      .snapshots()
      .map((s) => s.docs.map(Church.fromDoc).toList());

  /// 교회 한 곳 (앱 운영자 전용). 없으면 null.
  Stream<Church?> church(String churchId) => _paths
      .church(churchId)
      .snapshots()
      .map((s) => s.exists ? Church.fromDoc(s) : null);

  /// 앱 운영자는 교회 회원이 아니므로, 예전에 잘못 남은 내 교인 문서를 모두 지운다.
  /// 앱 운영자는 회원이 아니어도 교회의 정보 · 인원 · 입장 · 부서 · 콘텐츠를 고칠 수 있다 (보안 규칙이 허용한다).
  Future<void> removeOwnMemberships() async {
    final mine = await _paths.allMembers
        .where('uid', isEqualTo: _auth.uid)
        .get();
    for (final d in mine.docs) {
      await d.reference.delete();
    }
  }

  /// 가입한 모든 회원 (앱 운영자 전용, 최근 가입 순).
  Stream<List<UserProfile>> users() => _db
      .collection('users')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(UserProfile.fromDoc).toList());

  /// 모든 교회의 교인 정보 (앱 운영자 전용). 회원이 어느 교회·부서에 속하는지 보여줄 때 쓴다.
  Stream<List<Member>> allMembers() => _paths.allMembers.snapshots().map(
    (s) => s.docs
        .map(Member.fromDoc)
        .where((m) => !m.isAppOperator && m.status != MemberStatus.removed)
        .toList(),
  );

  /// 모든 교회의 부서 (앱 운영자 전용).
  Stream<List<Department>> allDepartments() => _db
      .collectionGroup('departments')
      .snapshots()
      .map(
        (s) => [
          for (final d in s.docs)
            Department(
              d.id,
              d.data()['name'] as String? ?? '',
              churchId: d.reference.parent.parent!.id,
            ),
        ],
      );

  /// 회원의 이름·전화번호를 고친다. 소속된 모든 교회의 교인 정보에도 같이 반영한다.
  Future<void> updateUser(
    String uid, {
    required String name,
    required String phone,
    String address = '',
    String birthDate = '',
    String photoUrl = '',
  }) async {
    final n = name.trim();
    final p = phone.trim();
    if (n.isEmpty || n.length > 30) {
      throw const AppException('이름은 1~30자로 입력해 주세요.');
    }
    if (p.length < 8 || p.length > 20) {
      throw const AppException('전화번호를 8~20자로 입력해 주세요.');
    }
    final b = birthDate.trim();
    if (address.trim().length > 200) {
      throw const AppException('주소는 200자까지 쓸 수 있어요.');
    }
    if (b.isNotEmpty && DateTime.tryParse(b) == null) {
      throw const AppException('생년월일 형식이 올바르지 않아요.');
    }
    final data = {
      'name': n,
      'phone': p,
      'address': address.trim(),
      'birthDate': b,
      'photoUrl': photoUrl.trim(),
    };
    await _db.collection('users').doc(uid).update(data);
    final mine = await _paths.allMembers.where('uid', isEqualTo: uid).get();
    final batch = _db.batch();
    for (final m in mine.docs) {
      batch.update(m.reference, data);
    }
    await batch.commit();
  }

  /// 교회 썸네일을 올리고 주소를 돌려준다. 저장([updateChurch])은 따로 한다.
  Future<String> uploadChurchThumbnail(
    String churchId,
    String fileName,
    Uint8List bytes,
  ) =>
      _contents.uploadThumbnailTo('churches/$churchId/thumbnail', bytes: bytes);

  /// 회원의 프로필 사진을 올리고 주소를 돌려준다. 저장([updateUser])은 따로 한다.
  Future<String> uploadUserPhoto(
    String uid,
    String fileName,
    Uint8List bytes,
  ) => _contents.uploadThumbnailTo('users/$uid/avatar', bytes: bytes);

  /// 교회 정보(이름·전화번호·주소·썸네일)를 고친다. 이름이 바뀌면 교인 정보와 초대 코드에 담긴
  /// 교회 이름도 같이 고쳐서, 어디서나 같은 이름이 보이게 한다.
  Future<void> updateChurch(
    String churchId, {
    required String name,
    required String phone,
    required String address,
    String thumbnailUrl = '',
  }) async {
    final n = name.trim();
    final p = phone.trim();
    final a = address.trim();
    if (n.isEmpty || n.length > 50) {
      throw const AppException('교회 이름은 1~50자로 입력해 주세요.');
    }
    if (p.length < 8 || p.length > 20) {
      throw const AppException('교회 전화번호를 8~20자로 입력해 주세요.');
    }
    if (a.isEmpty || a.length > 200) {
      throw const AppException('교회 주소를 입력해 주세요.');
    }
    final ref = _paths.church(churchId);
    final before = (await ref.get()).data()?['name'] as String?;
    await ref.update({
      'name': n,
      'phone': p,
      'address': a,
      'thumbnailUrl': thumbnailUrl.trim(),
    });
    if (before == n) return;

    final targets = [
      ...(await _paths.members(churchId).get()).docs,
      ...(await _paths.inviteCodes.where('churchId', isEqualTo: churchId).get())
          .docs,
    ];
    // 한 번에 쓸 수 있는 양(500건)을 넘지 않게 나눠서 쓴다.
    for (var i = 0; i < targets.length; i += 400) {
      final batch = _db.batch();
      for (final d in targets.skip(i).take(400)) {
        batch.update(d.reference, {'churchName': n});
      }
      await batch.commit();
    }
  }

  /// 교회를 직접 등록한다. 교회 운영자는 이후 초대 코드로 들어온 교인에게 역할을 지정해 정한다.
  Future<void> register({
    required String name,
    String phone = '',
    required String address,
    bool requirePhone = true,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) throw const AppException('교회 이름을 입력해 주세요.');
    if (requirePhone && phone.trim().length < 8) {
      throw const AppException('교회 전화번호를 입력해 주세요.');
    }
    if (address.trim().isEmpty) throw const AppException('교회 주소를 입력해 주세요.');

    return _paths.churches.doc().set({
      'name': trimmedName,
      'phone': phone.trim(),
      'address': address.trim(),
      'createdBy': _auth.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 앱 운영자가 교회를 관리할 때 쓰는 화면용 교인 정보. 저장되지 않으며 소속을 뜻하지 않는다.
  /// 기존 교인 관리 화면(교인·초대 코드·부서)을 그대로 쓰기 위한 것이다.
  Member operatorViewOf(Church church) => Member(
    id: _auth.uid,
    churchId: church.id,
    churchName: church.name,
    name: _auth.displayName,
    role: Role.admin,
    status: MemberStatus.approved,
    isOperatorView: true,
  );
}
