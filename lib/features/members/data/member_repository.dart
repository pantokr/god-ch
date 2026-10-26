import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/app_exception.dart';
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

  /// 인원 상세 관리: 넘긴 항목만 저장한다. 이름·전화번호·소속 부서는 한 번에 쓰고,
  /// 역할·상태는 규칙이 따로 허용하므로 따로 쓴다.
  Future<void> saveMember(
    Member m, {
    String? name,
    String? phone,
    String? address,
    String? birthDate,
    List<String>? departmentIds,
    Role? role,
    MemberStatus? status,
  }) async {
    final info = <String, Object>{};
    if (name != null) {
      final n = name.trim();
      if (n.isEmpty || n.length > 30) {
        throw const AppException('이름은 1~30자로 입력해 주세요.');
      }
      info['name'] = n;
    }
    if (phone != null) {
      final p = phone.trim();
      if (p.isNotEmpty && (p.length < 8 || p.length > 20)) {
        throw const AppException('전화번호를 8~20자로 입력해 주세요.');
      }
      info['phone'] = p;
    }
    if (address != null) {
      if (address.trim().length > 200) {
        throw const AppException('주소는 200자까지 쓸 수 있어요.');
      }
      info['address'] = address.trim();
    }
    if (birthDate != null) {
      final b = birthDate.trim();
      if (b.isNotEmpty && DateTime.tryParse(b) == null) {
        throw const AppException('생년월일 형식이 올바르지 않아요.');
      }
      info['birthDate'] = b;
    }
    if (departmentIds != null) info['departmentIds'] = departmentIds;
    final doc = _paths.members(m.churchId).doc(m.id);
    if (info.isNotEmpty) await doc.update(info);
    if (role != null) await doc.update({'role': role.name});
    if (status != null) await doc.update({'status': status.name});
  }

  /// 교역자가 교인을 부서에 넣는다 (이미 있으면 그대로).
  Future<void> addToDepartment(String churchId, String userId, String deptId) =>
      _paths.members(churchId).doc(userId).update({
        'departmentIds': FieldValue.arrayUnion([deptId]),
      });

  /// 교역자가 교인을 부서에서 뺀다.
  Future<void> removeFromDepartment(
    String churchId,
    String userId,
    String deptId,
  ) => _paths.members(churchId).doc(userId).update({
    'departmentIds': FieldValue.arrayRemove([deptId]),
  });

  /// 내 소속 부서를 통째로 저장한다 (선택 사항이라 빈 목록도 가능).
  Future<void> setMyDepartments(String churchId, List<String> ids) =>
      _paths.members(churchId).doc(_auth.uid).update({'departmentIds': ids});
}
