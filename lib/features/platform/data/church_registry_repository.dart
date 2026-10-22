import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/app_exception.dart';
import '../../../data/firestore_paths.dart';
import '../../../data/models/church.dart';
import '../../../data/models/member.dart';
import '../../../data/models/user_profile.dart';
import '../../auth/data/auth_repository.dart';

/// 앱 운영자 패널의 데이터: 등록된 교회 목록과 직접 등록, 전체 회원.
/// 앱 운영자는 교회에 소속되지 않으므로 교회의 교인으로 등록되지 않는다.
/// (교회 생성 요청의 승인·거절은 [ChurchRequestRepository]가 맡는다.)
class ChurchRegistryRepository {
  ChurchRegistryRepository(FirebaseFirestore db, this._auth)
    : _db = db,
      _paths = FirestorePaths(db);

  final FirebaseFirestore _db;
  final FirestorePaths _paths;
  final AuthRepository _auth;

  /// 등록된 모든 교회 (앱 운영자 전용).
  Stream<List<Church>> churches() => _paths.churches
      .orderBy('createdAt')
      .snapshots()
      .map((s) => s.docs.map(Church.fromDoc).toList());

  /// 가입한 모든 회원 (앱 운영자 전용, 최근 가입 순).
  Stream<List<UserProfile>> users() => _db
      .collection('users')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(UserProfile.fromDoc).toList());

  /// 교회를 직접 등록한다. 교회 운영자는 이후 초대 코드로 들어온 교인에게 역할을 지정해 정한다.
  Future<void> register({
    required String name,
    String phone = '',
    required String address,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) throw const AppException('교회 이름을 입력해 주세요.');
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
    email: _auth.email,
    role: Role.admin,
    status: MemberStatus.approved,
  );
}
