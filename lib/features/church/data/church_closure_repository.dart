import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/app_exception.dart';
import '../../../data/firestore_codec.dart';
import '../../../data/firestore_paths.dart';
import '../../../data/models/app_notification.dart';
import '../../../data/models/church_closure_request.dart';
import '../../../data/models/church_request.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/profile_repository.dart';

/// 교회 폐쇄 요청: 교회 운영자가 요청하고, 앱 운영자가 승인하면 교회가 폐쇄 상태(closed)가 된다.
/// 요청도 폐쇄도 아무것도 지우지 않는다 (기록 보관). 폐쇄된 교회는 교인이 쓸 수 없을 뿐이다.
class ChurchClosureRepository {
  ChurchClosureRepository(FirebaseFirestore db, this._auth, this._profiles)
    : _db = db,
      _paths = FirestorePaths(db);

  final FirebaseFirestore _db;
  final FirestorePaths _paths;
  final AuthRepository _auth;
  final ProfileRepository _profiles;

  CollectionReference<Json> get _col => _db.collection('churchClosureRequests');

  // ---- 교회 운영자 ----

  /// 이 교회에 대한 가장 최근 요청 (대기 중인 요청이 있으면 그것). 없으면 null.
  Stream<ChurchClosureRequest?> latestFor(String churchId) =>
      _col.where('churchId', isEqualTo: churchId).snapshots().map((s) {
        final list = s.docs.map(ChurchClosureRequest.fromDoc).toList()
          ..sort(
            (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
              a.createdAt ?? DateTime.now(),
            ),
          );
        for (final r in list) {
          if (r.status == RequestStatus.pending) return r;
        }
        return list.isEmpty ? null : list.first;
      });

  Future<void> request({
    required String churchId,
    required String churchName,
    required String reason,
  }) async {
    final why = reason.trim();
    if (why.isEmpty) throw const AppException('폐쇄 사유를 입력해 주세요.');
    if (why.length > ChurchClosureRequest.maxReasonLength) {
      throw const AppException(
        '사유는 ${ChurchClosureRequest.maxReasonLength}자까지 쓸 수 있어요.',
      );
    }
    final profile = await _profiles.requireCurrent();
    await _col.add({
      'churchId': churchId,
      'churchName': churchName,
      'requesterId': _auth.uid,
      'requesterName': profile.name,
      'reason': why,
      'status': RequestStatus.pending.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ---- 앱 운영자 ----

  /// 처리를 기다리는 폐쇄 요청 (오래된 순).
  Stream<List<ChurchClosureRequest>> pending() => _col
      .where('status', isEqualTo: RequestStatus.pending.name)
      .snapshots()
      .map(
        (s) => s.docs.map(ChurchClosureRequest.fromDoc).toList()
          ..sort(
            (a, b) => (a.createdAt ?? DateTime.now()).compareTo(
              b.createdAt ?? DateTime.now(),
            ),
          ),
      );

  /// 승인: 교회를 폐쇄 상태로 바꾸고 요청자에게 알린다. 교회와 기록은 그대로 둔다.
  Future<void> approve(ChurchClosureRequest r) {
    final batch = _db.batch();
    batch.update(_col.doc(r.id), {
      'status': RequestStatus.approved.name,
      'reviewedBy': _auth.uid,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_paths.church(r.churchId), {
      'closed': true,
      'closedAt': FieldValue.serverTimestamp(),
      'closedBy': _auth.uid,
    });
    batch.set(_notice(r.requesterId), {
      'type': NotificationType.general.name,
      'title': '${r.churchName} 교회 폐쇄 요청이 승인되었어요',
      'body': '교회는 폐쇄되었고, 기록은 보관돼요.',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return batch.commit();
  }

  Future<void> reject(ChurchClosureRequest r, String reason) {
    final why = reason.trim();
    final batch = _db.batch();
    batch.update(_col.doc(r.id), {
      'status': RequestStatus.rejected.name,
      'rejectReason': why,
      'reviewedBy': _auth.uid,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
    batch.set(_notice(r.requesterId), {
      'type': NotificationType.general.name,
      'title': '${r.churchName} 교회 폐쇄 요청이 거절되었어요',
      'body': why.isEmpty ? '운영자가 요청을 거절했어요.' : '사유: $why',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return batch.commit();
  }

  DocumentReference<Json> _notice(String uid) =>
      _db.collection('users').doc(uid).collection('notifications').doc();
}
