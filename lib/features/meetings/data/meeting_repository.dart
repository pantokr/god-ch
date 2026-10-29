import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/app_exception.dart';
import '../../../data/firestore_paths.dart';
import '../../../data/models/meeting.dart';
import '../../auth/data/auth_repository.dart';

/// 교회 모임을 읽고 쓴다 (`churches/{id}/meetings`). 교인이 모임을 만들면 모임장이 되고,
/// 다른 교인은 참여를 신청한다. 권한과 정원은 `firestore.rules`가 강제한다.
class MeetingRepository {
  MeetingRepository(FirebaseFirestore db, this._auth)
    : _paths = FirestorePaths(db);

  final FirestorePaths _paths;
  final AuthRepository _auth;

  CollectionReference<Map<String, dynamic>> _col(String churchId) =>
      _paths.church(churchId).collection('meetings');

  /// 모임 날짜가 가까운 쪽이 위. 지워진 모임은 뺀다.
  Stream<List<Meeting>> latest(String churchId, {int limit = 100}) =>
      _col(churchId)
          .orderBy('date', descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (s) => [
              for (final d in s.docs)
                if (d.data()['deleted'] != true) Meeting.fromDoc(d),
            ],
          );

  /// 모임 한 건. 지워졌거나 없으면 null.
  Stream<Meeting?> one(String churchId, String id) =>
      _col(churchId).doc(id).snapshots().map((s) {
        if (!s.exists) return null;
        final m = Meeting.fromDoc(s);
        return m.deleted ? null : m;
      });

  String _check(String title, String description, String place, int capacity) {
    final t = title.trim();
    if (t.isEmpty) throw const AppException('제목을 입력해 주세요.');
    if (t.length > Meeting.maxTitle) {
      throw AppException('제목은 ${Meeting.maxTitle}자까지 쓸 수 있어요.');
    }
    if (description.trim().length > Meeting.maxDescription) {
      throw AppException('소개는 ${Meeting.maxDescription}자까지 쓸 수 있어요.');
    }
    if (place.trim().length > Meeting.maxPlace) {
      throw AppException('장소는 ${Meeting.maxPlace}자까지 쓸 수 있어요.');
    }
    if (capacity < 2 || capacity > Meeting.maxCapacity) {
      throw AppException('정원은 2명에서 ${Meeting.maxCapacity}명까지예요.');
    }
    return t;
  }

  /// 새 모임. 만든 사람이 모임장이고 첫 참여자다.
  Future<void> create(
    String churchId, {
    required String leaderName,
    required String title,
    required String description,
    required String place,
    required DateTime date,
    required int capacity,
  }) {
    final t = _check(title, description, place, capacity);
    return _col(churchId).add({
      'title': t,
      'description': description.trim(),
      'place': place.trim(),
      'date': Timestamp.fromDate(date),
      'capacity': capacity,
      'leaderId': _auth.uid,
      'leaderName': leaderName,
      'participantIds': [_auth.uid],
      'likedBy': <String>[],
      'views': 0,
      'deleted': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 모임 내용을 고친다 (모임장 · 교역자). 정원은 이미 참여한 사람보다 적게 줄일 수 없다.
  Future<void> update(
    String churchId,
    Meeting m, {
    required String title,
    required String description,
    required String place,
    required DateTime date,
    required int capacity,
  }) {
    final t = _check(title, description, place, capacity);
    if (capacity < m.joined) {
      throw AppException('이미 ${m.joined}명이 참여해서 정원을 그보다 줄일 수 없어요.');
    }
    return _col(churchId).doc(m.id).update({
      'title': t,
      'description': description.trim(),
      'place': place.trim(),
      'date': Timestamp.fromDate(date),
      'capacity': capacity,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 모임을 지운 것으로 표시한다 (기록 보관).
  Future<void> delete(String churchId, String id) => _col(churchId)
      .doc(id)
      .update({
        'deleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': _auth.uid,
      });

  /// 참여를 신청하거나 취소한다. 정원을 넘으면 규칙이 거부한다.
  Future<void> setJoined(String churchId, String id, {required bool joined}) =>
      _col(churchId).doc(id).update({
        'participantIds': joined
            ? FieldValue.arrayUnion([_auth.uid])
            : FieldValue.arrayRemove([_auth.uid]),
      });

  Future<void> setLike(String churchId, String id, {required bool liked}) =>
      _col(churchId).doc(id).update({
        'likedBy': liked
            ? FieldValue.arrayUnion([_auth.uid])
            : FieldValue.arrayRemove([_auth.uid]),
      });

  Future<void> addView(String churchId, String id) =>
      _col(churchId).doc(id).update({'views': FieldValue.increment(1)});
}
