import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../data/firestore_paths.dart';
import '../../../data/models/member.dart';
import '../../auth/data/auth_repository.dart';

/// 교회별 교인 목록과 승인·역할·소속 부서 변경.
class MemberRepository {
  MemberRepository(FirebaseFirestore db, this._auth)
    : _paths = FirestorePaths(db);

  final FirestorePaths _paths;
  final AuthRepository _auth;

  Stream<List<Member>> members(String churchId) => _paths
      .members(churchId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Member.fromDoc).toList());

  Future<void> setStatus(String churchId, String userId, MemberStatus status) =>
      _paths.members(churchId).doc(userId).update({'status': status.name});

  Future<void> setRole(String churchId, String userId, Role role) =>
      _paths.members(churchId).doc(userId).update({'role': role.name});

  /// 내 소속 부서를 통째로 저장한다 (선택 사항이라 빈 목록도 가능).
  Future<void> setMyDepartments(String churchId, List<String> ids) =>
      _paths.members(churchId).doc(_auth.uid).update({'departmentIds': ids});
}
