import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/app_exception.dart';
import '../../../data/firestore_paths.dart';
import '../../../data/models/church_features.dart';
import '../../../data/models/affiliation.dart';
import '../../auth/data/auth_repository.dart';
import 'admin_affiliations.dart';

/// 소속 목록 / 만들기 / 이름 변경. 소속 선택은 [MemberRepository]에서 한다.
class AffiliationRepository {
  AffiliationRepository(FirebaseFirestore db, this._auth)
    : _paths = FirestorePaths(db);

  final FirestorePaths _paths;
  final AuthRepository _auth;

  Stream<List<Affiliation>> affiliations(String churchId) => _paths
      .affiliations(churchId)
      .orderBy('createdAt')
      .snapshots()
      .map(
        (s) => [
          for (final d in s.docs)
            // 지운 소속은 문서를 남기고 목록에서만 뺀다.
            if (d.data()['deleted'] != true)
              Affiliation(d.id, d.data()['name'] as String? ?? ''),
        ],
      );

  DocumentReference<Map<String, dynamic>> _features(String churchId) =>
      _paths.church(churchId).collection('settings').doc('features');

  /// 소속별로 기도 · 말씀 탭을 쓸 수 있는지. 설정한 적 없으면 모두 허용.
  Stream<ChurchFeatures> features(String churchId) =>
      _features(churchId).snapshots().map(ChurchFeatures.fromDoc);

  Future<void> setFeatures(String churchId, ChurchFeatures features) =>
      _features(churchId).set(features.toMap());

  Future<void> create(String churchId, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw const AppException('소속 이름을 입력해 주세요.');
    // 새 소속에도 교회 운영자가 자동으로 속한다.
    return _paths
        .affiliations(churchId)
        .add({
          'name': trimmed,
          'createdBy': _auth.uid,
          'createdAt': FieldValue.serverTimestamp(),
        })
        // 교회 관리자가 아닌 사람이 만들 때는 맞추기가 막힐 수 있다: 소속 생성은 이미 끝났으니 오류로 보지 않는다.
        .then(
          (_) => syncAdminAffiliations(_paths, churchId).catchError((_) {}),
        );
  }

  /// 소속을 지운 것으로 표시한다 (문서와 교인의 소속 기록은 남기고 목록에서만 사라진다).
  Future<void> delete(String churchId, String id) =>
      _paths.affiliations(churchId).doc(id).update({
        'deleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': _auth.uid,
      });

  Future<void> rename(String churchId, String id, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw const AppException('소속 이름을 입력해 주세요.');
    return _paths.affiliations(churchId).doc(id).update({'name': trimmed});
  }
}
