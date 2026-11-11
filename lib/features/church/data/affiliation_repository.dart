import '../../../data/models/activity_log.dart';
import '../../activity/data/activity_log_repository.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/app_exception.dart';
import '../../../data/firestore_paths.dart';
import '../../../data/models/affiliation.dart';
import '../../auth/data/auth_repository.dart';
import 'admin_affiliations.dart';

/// 소속 목록 / 만들기 / 이름 변경. 소속 선택은 [MemberRepository]에서 한다.
class AffiliationRepository {
  AffiliationRepository(FirebaseFirestore db, this._auth, {this.activity})
    : _paths = FirestorePaths(db);

  final FirestorePaths _paths;
  final AuthRepository _auth;

  /// 활동 기록 (없으면 남기지 않는다).
  final ActivityLogRepository? activity;

  Stream<List<Affiliation>> affiliations(String churchId) => _paths
      .affiliations(churchId)
      .snapshots()
      .map(
        (s) => [
          for (final d in s.docs)
            // 지운 소속은 문서를 남기고 목록에서만 뺀다.
            if (d.data()['deleted'] != true)
              Affiliation(d.id, d.data()['name'] as String? ?? ''),
        ].sortedByName(),
      );

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
        .then((ref) {
          activity?.log(
            ActivityType.affiliationChange,
            churchId: churchId,
            targetId: ref.id,
            summary: '소속 생성 · $trimmed',
          );
          return syncAdminAffiliations(_paths, churchId).catchError((_) {});
        });
  }

  /// 소속을 지운 것으로 표시한다 (문서와 교인의 소속 기록은 남기고 목록에서만 사라진다).
  Future<void> delete(String churchId, String id) => _paths
      .affiliations(churchId)
      .doc(id)
      .update({
        'deleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': _auth.uid,
      })
      .logged(
        activity,
        ActivityType.affiliationChange,
        churchId: churchId,
        targetId: id,
        summary: '소속 삭제',
      );

  Future<void> rename(String churchId, String id, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw const AppException('소속 이름을 입력해 주세요.');
    return _paths
        .affiliations(churchId)
        .doc(id)
        .update({'name': trimmed})
        .logged(
          activity,
          ActivityType.affiliationChange,
          churchId: churchId,
          targetId: id,
          summary: '소속 이름 변경 · $trimmed',
        );
  }
}
