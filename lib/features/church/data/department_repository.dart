import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/app_exception.dart';
import '../../../data/firestore_paths.dart';
import '../../../data/models/department.dart';
import '../../auth/data/auth_repository.dart';

/// 부서 목록 / 만들기 / 이름 변경. 소속 선택은 [MemberRepository]에서 한다.
class DepartmentRepository {
  DepartmentRepository(FirebaseFirestore db, this._auth)
    : _paths = FirestorePaths(db);

  final FirestorePaths _paths;
  final AuthRepository _auth;

  Stream<List<Department>> departments(String churchId) => _paths
      .departments(churchId)
      .orderBy('createdAt')
      .snapshots()
      .map(
        (s) => s.docs
            .map((d) => Department(d.id, d.data()['name'] as String? ?? ''))
            .toList(),
      );

  Future<void> create(String churchId, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw const AppException('부서 이름을 입력해 주세요.');
    return _paths.departments(churchId).add({
      'name': trimmed,
      'createdBy': _auth.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rename(String churchId, String id, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw const AppException('부서 이름을 입력해 주세요.');
    return _paths.departments(churchId).doc(id).update({'name': trimmed});
  }
}
