import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/app_exception.dart';
import '../../../data/firestore_paths.dart';
import '../../../data/models/church_features.dart';
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

  DocumentReference<Map<String, dynamic>> _features(String churchId) =>
      _paths.church(churchId).collection('settings').doc('features');

  /// 부서별로 기도 · 말씀 탭을 쓸 수 있는지. 설정한 적 없으면 모두 허용.
  Stream<ChurchFeatures> features(String churchId) =>
      _features(churchId).snapshots().map(ChurchFeatures.fromDoc);

  Future<void> setFeatures(String churchId, ChurchFeatures features) =>
      _features(churchId).set(features.toMap());

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
