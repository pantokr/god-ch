import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../data/firestore_codec.dart';
import '../../../data/firestore_paths.dart';
import '../../../data/models/prayer.dart';
import '../../../data/models/prayer_settings.dart';
import '../../../data/models/reaction.dart';
import '../../../data/models/text_entry.dart';
import '../../auth/data/auth_repository.dart';

/// 기도제목과 그 하위 데이터(응원, 교역자 댓글, 비공개 글 답변, 열람 기록).
/// 접근 권한은 firestore.rules가 강제한다.
class PrayerRepository {
  PrayerRepository(FirebaseFirestore db, this._auth)
    : _db = db,
      _paths = FirestorePaths(db);

  final FirebaseFirestore _db;
  final FirestorePaths _paths;
  final AuthRepository _auth;

  // ---- 운영 설정 ----

  DocumentReference<Json> _settings(String churchId) =>
      _paths.church(churchId).collection('settings').doc('prayer');

  /// 교회가 정한 기도 요청 운영 설정. 정한 적 없으면 표준 설정이다.
  Stream<PrayerSettings> settings(String churchId) =>
      _settings(churchId).snapshots().map(PrayerSettings.fromDoc);

  Future<PrayerSettings> loadSettings(String churchId) async =>
      PrayerSettings.fromDoc(await _settings(churchId).get());

  Future<void> saveSettings(String churchId, PrayerSettings settings) =>
      _settings(churchId).set(settings.toMap());

  // ---- 조회 ----
  //
  // 복합 색인이 필요 없게 설계했다: 조회는 같음(==) 조건만 쓰고 orderBy를 붙이지 않는다.
  // 같음 조건만 있는 조회는 단일 필드 색인(자동)만으로 되고, 결과는 문서 ID 순서로 나온다.
  // 글의 문서 ID를 시간 역순으로 만들기 때문에([newId]) 그 순서가 곧 최신순이다.
  // 새 조회를 더할 때도 orderBy와 where를 함께 쓰지 말 것 (test/no_composite_query_test.dart가 막는다).

  /// 글 ID: 시간이 지날수록 이름순으로 앞에 오도록 (9999999999999 - 지금 밀리초)를 앞에 붙인다.
  static String newId() {
    final reversed = (9999999999999 - DateTime.now().millisecondsSinceEpoch)
        .toString()
        .padLeft(13, '0');
    final rnd = Random.secure();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final tail = List.generate(6, (_) => chars[rnd.nextInt(chars.length)]);
    return '${reversed}_${tail.join()}';
  }

  /// 한 번에 읽는 글 수의 기본값.
  static const pageSize = 100;

  /// 반드시 visibility/deleted 조건을 쿼리에 포함해야 규칙을 통과한다.
  /// [affiliationId]가 null이면 교회 전체 글, 값이 있으면 그 소속 전용 글만 가져온다. 최신 글부터.
  Stream<List<Prayer>> publicFeed(
    String churchId, {
    String? affiliationId,
    int limit = pageSize,
  }) => _paths
      .prayers(churchId)
      .where('visibility', isEqualTo: PrayerVisibility.public.name)
      .where('deleted', isEqualTo: false)
      .where('affiliationId', isEqualTo: affiliationId)
      .limit(limit)
      .snapshots()
      .map(_toPrayers);

  Stream<List<Prayer>> myPrayers(String churchId, {int limit = pageSize}) =>
      _paths
          .prayers(churchId)
          .where('authorId', isEqualTo: _auth.uid)
          .where('deleted', isEqualTo: false)
          .limit(limit)
          .snapshots()
          .map(_toPrayers);

  /// 교역자 전용: 비공개·삭제된 글 포함 전체.
  Stream<List<Prayer>> allPrayers(String churchId, {int limit = pageSize}) =>
      _paths.prayers(churchId).limit(limit).snapshots().map(_toPrayers);

  Stream<Prayer?> prayer(String churchId, String id) => _paths
      .prayers(churchId)
      .doc(id)
      .snapshots()
      .map((s) => s.exists ? Prayer.fromDoc(s) : null);

  /// 문서 ID 순서(= 최신순)를 그대로 쓴다. 혹시 섞여 있어도 만든 시각으로 한 번 더 맞춘다.
  List<Prayer> _toPrayers(QuerySnapshot<Json> s) {
    final list = s.docs.map(Prayer.fromDoc).toList();
    list.sort(
      (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
        a.createdAt ?? DateTime.now(),
      ),
    );
    return list;
  }

  // ---- 쓰기 ----

  Future<void> create(
    String churchId, {
    required String title,
    required String content,
    required PrayerVisibility visibility,
    String? affiliationId,
  }) => _paths.prayers(churchId).doc(newId()).set({
    'authorId': _auth.uid,
    'affiliationId': affiliationId,
    'title': title,
    'content': content,
    'visibility': visibility.name,
    'deleted': false,
    'views': 0,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Future<void> update(
    String churchId,
    String id, {
    required String title,
    required String content,
    required PrayerVisibility visibility,
  }) => _paths.prayers(churchId).doc(id).update({
    'title': title,
    'content': content,
    'visibility': visibility.name,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  /// 교역자가 공개 글의 제목·내용을 고친다 (유해하거나 고쳐야 할 내용). 기록은 moderatedBy/At에 남는다.
  Future<void> editByStaff(
    String churchId,
    String id, {
    required String title,
    required String content,
  }) => _paths.prayers(churchId).doc(id).update({
    'title': title,
    'content': content,
    'updatedAt': FieldValue.serverTimestamp(),
    'moderatedBy': _auth.uid,
    'moderatedAt': FieldValue.serverTimestamp(),
  });

  Future<void> deleteOwn(String churchId, String id) =>
      _softDelete(churchId, id, '본인 삭제');

  Future<void> deleteByStaff(String churchId, String id, String reason) =>
      _softDelete(churchId, id, reason);

  Future<void> _softDelete(String churchId, String id, String reason) =>
      _paths.prayers(churchId).doc(id).update({
        'deleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': _auth.uid,
        'deleteReason': reason,
      });

  Future<void> restore(String churchId, String id) =>
      _paths.prayers(churchId).doc(id).update({
        'deleted': false,
        'deletedAt': FieldValue.delete(),
        'deletedBy': FieldValue.delete(),
        'deleteReason': FieldValue.delete(),
      });

  /// 기도제목을 열 때 조회수를 하나 올린다. 규칙이 +1만 허용한다.
  Future<void> addView(String churchId, String id) => _paths
      .prayers(churchId)
      .doc(id)
      .update({'views': FieldValue.increment(1)});

  Future<void> markResponsesSeen(String churchId, String id) => _paths
      .prayers(churchId)
      .doc(id)
      .update({'responseSeenAt': FieldValue.serverTimestamp()});

  // ---- 이모티콘 응원 ----

  /// 반응한 사람의 정보는 노출하지 않고, 이모티콘별 개수와 내 선택만 계산한다.
  Stream<ReactionSummary> reactions(String churchId, String prayerId) => _paths
      .prayers(churchId)
      .doc(prayerId)
      .collection('reactions')
      .snapshots()
      .map((s) {
        final counts = <String, int>{};
        final mine = <String>{};
        for (final d in s.docs) {
          // 취소한 반응(active: false)은 기록으로만 남고 세지 않는다.
          if (d.data()['active'] == false) continue;
          final type = d.data()['type'] as String? ?? '';
          counts[type] = (counts[type] ?? 0) + 1;
          if (d.data()['uid'] == _auth.uid) mine.add(type);
        }
        return ReactionSummary(counts, mine);
      });

  Future<void> toggleReaction(
    String churchId,
    String prayerId,
    String type,
    bool currentlyOn,
  ) {
    final ref = _paths
        .prayers(churchId)
        .doc(prayerId)
        .collection('reactions')
        .doc('${_auth.uid}_$type');
    // 반응은 지우지 않고 켜고 끄는 표시(active)만 바꾼다.
    return ref.get().then((snap) {
      if (snap.exists) {
        return ref.update({
          'active': !currentlyOn,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      return ref.set({
        'uid': _auth.uid,
        'type': type,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ---- 교역자 댓글 / 비공개 글 답변 ----

  Stream<List<TextEntry>> comments(String churchId, String prayerId) =>
      _entries(churchId, prayerId, 'comments');

  Stream<List<TextEntry>> responses(String churchId, String prayerId) =>
      _entries(churchId, prayerId, 'responses');

  Stream<List<TextEntry>> _entries(
    String churchId,
    String prayerId,
    String sub,
  ) => _paths.prayers(churchId).doc(prayerId).collection(sub).snapshots().map((
    s,
  ) {
    final list = [
      for (final d in s.docs)
        TextEntry(
          d.id,
          d.data()['content'] as String? ?? '',
          toDate(d.data()['createdAt']),
        ),
    ];
    // 오래된 순. 서버가 시각을 확정하기 전의 글은 맨 뒤.
    list.sort(
      (a, b) => (a.createdAt ?? DateTime(9999)).compareTo(
        b.createdAt ?? DateTime(9999),
      ),
    );
    return list;
  });

  Future<void> addComment(String churchId, String prayerId, String content) =>
      _paths.prayers(churchId).doc(prayerId).collection('comments').add({
        'authorId': _auth.uid,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<void> addResponse(
    String churchId,
    String prayerId,
    String content,
  ) async {
    final prayerRef = _paths.prayers(churchId).doc(prayerId);
    final batch = _db.batch();
    batch.set(prayerRef.collection('responses').doc(), {
      'staffId': _auth.uid,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(prayerRef, {'lastResponseAt': FieldValue.serverTimestamp()});
    await batch.commit();
  }

  /// 교역자가 타인의 비공개 글을 열람할 때 남기는 기록.
  Future<void> logPrivateAccess(String churchId, String prayerId) =>
      _paths.accessLogs(churchId).add({
        'staffId': _auth.uid,
        'prayerId': prayerId,
        'at': FieldValue.serverTimestamp(),
      });
}
