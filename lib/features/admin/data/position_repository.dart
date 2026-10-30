import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/app_exception.dart';
import '../../../data/firestore_paths.dart';
import '../../../data/models/permission.dart';
import '../../../data/models/position.dart';
import '../../auth/data/auth_repository.dart';

/// 직급을 읽고 쓰고, 교인에게 직급을 준다 (`churches/{id}/positions`). 교회 관리자만 쓴다.
/// 직급의 권한은 교인 문서의 `permissions`에 복사되어 있어서, 직급을 고치거나 지우면 그 직급의 교인 문서도 함께 고친다.
class PositionRepository {
  PositionRepository(FirebaseFirestore db, this._auth)
    : _db = db,
      _paths = FirestorePaths(db);

  final FirebaseFirestore _db;
  final FirestorePaths _paths;
  final AuthRepository _auth;

  CollectionReference<Map<String, dynamic>> _col(String churchId) =>
      _paths.church(churchId).collection('positions');

  /// 지워지지 않은 직급들 (이름순).
  Stream<List<Position>> positions(String churchId) =>
      _col(churchId).snapshots().map(
        (s) => [
          for (final d in s.docs)
            // 기본 직급(교역자 · 회원) 문서는 따로 보여 주므로 목록에서 뺀다.
            if (d.data()['deleted'] != true &&
                d.data()['builtIn'] != true &&
                !BuiltInPosition.isBuiltInId(d.id))
              Position.fromDoc(d),
        ]..sort((a, b) => a.name.compareTo(b.name)),
      );

  String _checkName(String name) {
    final n = name.trim();
    if (n.isEmpty) throw const AppException('직급 이름을 입력해 주세요.');
    if (n.length > Position.maxName) {
      throw AppException('직급 이름은 ${Position.maxName}자까지 쓸 수 있어요.');
    }
    return n;
  }

  /// 줄 수 없는 권한은 걸러내고 정해진 순서로 돌려준다.
  /// 줄 수 있는 권한만, 선행 권한이 없는 것은 빼고 저장한다.
  List<String> _clean(Set<String> keys) {
    final ok = Permission.consistent(keys);
    return [
      for (final p in Permission.delegable)
        if (ok.contains(p.key)) p.key,
    ];
  }

  Future<void> create(
    String churchId, {
    required String name,
    required Set<String> permissions,
  }) {
    final n = _checkName(name);
    return _col(churchId).add({
      'name': n,
      'permissions': _clean(permissions),
      'deleted': false,
      'createdBy': _auth.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 이름과 권한을 고치고, 이 직급을 가진 교인들의 권한도 같게 맞춘다.
  Future<void> update(
    String churchId,
    Position p, {
    required String name,
    required Set<String> permissions,
  }) async {
    final n = _checkName(name);
    final keys = _clean(permissions);
    await _col(churchId).doc(p.id).update({
      'name': n,
      'permissions': keys,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final holders = await _paths
        .members(churchId)
        .where('positionId', isEqualTo: p.id)
        .get();
    final batch = _db.batch();
    for (final d in holders.docs) {
      batch.update(d.reference, {'permissions': keys});
    }
    if (holders.docs.isNotEmpty) await batch.commit();
  }

  /// 직급을 지운 것으로 표시하고, 이 직급을 가진 교인에게서 직급과 권한을 뺀다.
  Future<void> delete(String churchId, Position p) async {
    await _col(churchId).doc(p.id).update({
      'deleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'deletedBy': _auth.uid,
    });
    final holders = await _paths
        .members(churchId)
        .where('positionId', isEqualTo: p.id)
        .get();
    final batch = _db.batch();
    for (final d in holders.docs) {
      batch.update(d.reference, {
        'positionId': null,
        'permissions': <String>[],
      });
    }
    if (holders.docs.isNotEmpty) await batch.commit();
  }

  /// 기본 직급(교역자 · 회원)의 권한을 정한다. 기본 직급은 지울 수 없고, 교회 관리자는 모든 권한이라 정하지 않는다.
  Future<void> saveBuiltIn(
    String churchId,
    BuiltInPosition position,
    Set<String> permissions,
  ) {
    if (position == BuiltInPosition.admin) {
      throw const AppException('교회 관리자는 모든 권한을 가져요.');
    }
    return _col(churchId).doc(position.id).set({
      'name': position.name,
      'permissions': _clean(permissions),
      'builtIn': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 교인에게 직급을 준다. [position]이 null이면 직급을 뺀다.
  Future<void> assign(String churchId, String memberId, Position? position) =>
      _paths.members(churchId).doc(memberId).update({
        'positionId': position?.id,
        'permissions': position == null
            ? <String>[]
            : _clean(position.permissions),
      });
}
