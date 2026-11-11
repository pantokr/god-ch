import '../../../data/models/activity_log.dart';
import '../../activity/data/activity_log_repository.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../data/shared_stream.dart';

import '../../../core/app_exception.dart';
import '../../../data/firestore_codec.dart';
import '../../../data/firestore_paths.dart';
import '../../../data/models/devotion_reflection.dart';
import '../../../data/models/my_comment.dart';
import '../../auth/data/auth_repository.dart';
import '../../notifications/data/activity_notice.dart';

/// 말씀묵상 글의 댓글을 읽고 쓴다. 읽기는 승인된 교인 모두, 쓰기는 댓글 권한이 있는 교인이고
/// 지우기는 본인 댓글 또는 타인 댓글 삭제 권한이 있는 사람이다 (`firestore.rules`가 강제한다).
class ReflectionRepository {
  ReflectionRepository(FirebaseFirestore db, this._auth, {this.activity})
    : _db = db,
      _paths = FirestorePaths(db);

  final FirebaseFirestore _db;
  final FirestorePaths _paths;
  final AuthRepository _auth;

  /// 활동 기록 (없으면 남기지 않는다).
  final ActivityLogRepository? activity;

  CollectionReference<Json> _col(String churchId, String devotionId) =>
      _paths.devotions(churchId).doc(devotionId).collection('reflections');

  /// 댓글: 최신 댓글이 위, 오래된 댓글이 아래로 이어진다. 최근 [limit]개까지만 읽는다. 지운 댓글은 뺀다.
  Stream<List<DevotionReflection>> latest(
    String churchId,
    String devotionId, {
    int limit = 100,
  }) => _col(churchId, devotionId)
      .orderBy('updatedAt', descending: true)
      .limit(limit)
      .snapshots()
      .map(
        (s) => s.docs
            .map(DevotionReflection.fromDoc)
            .where((r) => !r.deleted)
            .toList(),
      );

  /// 지우지 않은 댓글 수 (목록의 댓글 표시). 댓글을 비공개로 둔 교회에서는 교역자만 읽을 수 있다.
  /// 같은 조회(글마다의 댓글 수)를 카드마다 따로 듣지 않고 하나를 나눠 쓴다.
  final _shared = SharedStreams();

  Stream<int> count(String churchId, String devotionId) => _shared.of(
    'count/$churchId/$devotionId',
    () => _count(churchId, devotionId),
  );

  Stream<int> _count(String churchId, String devotionId) =>
      _col(churchId, devotionId).snapshots().map(
        (s) => s.docs.where((d) => d.data()['deleted'] != true).length,
      );

  /// 내가 쓴 댓글만 실시간으로 읽는다 (댓글을 비공개로 둔 교회에서 교인이 쓴다). 오래된 것이 위.
  Stream<List<DevotionReflection>> onlyMine(
    String churchId,
    String devotionId,
  ) => _col(churchId, devotionId)
      .where('authorId', isEqualTo: _auth.uid)
      .snapshots()
      .map(
        (s) =>
            s.docs
                .map(DevotionReflection.fromDoc)
                .where((r) => !r.deleted)
                .toList()
              ..sort(
                (a, b) => (a.updatedAt ?? DateTime(9999)).compareTo(
                  b.updatedAt ?? DateTime(9999),
                ),
              ),
      );

  /// 이 말씀묵상 글에 내가 쓴 댓글들.
  Future<List<DevotionReflection>> mineAll(
    String churchId,
    String devotionId,
  ) async {
    final s = await _col(
      churchId,
      devotionId,
    ).where('authorId', isEqualTo: _auth.uid).get();
    return [
      for (final d in s.docs)
        if (d.data()['deleted'] != true) DevotionReflection.fromDoc(d),
    ]..sort(
      (a, b) => (b.updatedAt ?? DateTime(9999)).compareTo(
        a.updatedAt ?? DateTime(9999),
      ),
    );
  }

  /// 새 댓글을 더한다 (한 사람이 여러 개를 달 수 있다).
  Future<void> add(
    String churchId,
    String devotionId, {
    required String authorName,
    required String text,
  }) {
    final t = text.trim();
    if (t.isEmpty) throw const AppException('댓글을 입력해 주세요.');
    if (t.length > DevotionReflection.maxLength) {
      throw AppException('댓글은 ${DevotionReflection.maxLength}자까지 쓸 수 있어요.');
    }
    return _addAndNotify(churchId, devotionId, authorName, t);
  }

  /// 댓글을 쓰고, 말씀묵상 글쓴이에게 "댓글" 알림을 같은 묶음으로 보낸다 (내 글이면 보내지 않는다).
  Future<void> _addAndNotify(
    String churchId,
    String devotionId,
    String authorName,
    String text,
  ) async {
    final post = await _paths.devotions(churchId).doc(devotionId).get();
    final batch = _db.batch()
      ..set(_col(churchId, devotionId).doc(), {
        'authorId': _auth.uid,
        'authorName': authorName,
        'text': text,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    ActivityNotice.add(
      batch,
      _db,
      me: _auth.uid,
      authorId: post.data()?['createdBy'] as String? ?? '',
      churchId: churchId,
      kind: ActivityNotice.devotion,
      postId: devotionId,
      postTitle: post.data()?['title'] as String? ?? '',
      actorName: authorName,
      comment: true,
    );
    await batch.commit();
    activity?.log(
      ActivityType.devotionReflection,
      churchId: churchId,
      targetId: devotionId,
    );
  }

  /// 내 댓글의 내용을 고친다 (고친 시각이 남는다).
  Future<void> edit(
    String churchId,
    String devotionId,
    String commentId,
    String text,
  ) {
    final t = text.trim();
    if (t.isEmpty) throw const AppException('댓글을 입력해 주세요.');
    if (t.length > DevotionReflection.maxLength) {
      throw AppException('댓글은 ${DevotionReflection.maxLength}자까지 쓸 수 있어요.');
    }
    return _col(churchId, devotionId).doc(commentId).update({
      'text': t,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 댓글을 지운 것으로 표시한다 (문서는 남긴다). 본인 댓글이거나 타인 댓글 삭제 권한이 있어야 한다.
  Future<void> delete(String churchId, String devotionId, String commentId) =>
      _col(churchId, devotionId).doc(commentId).update({
        'deleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': _auth.uid,
      });

  /// 내가 이 교회의 일정 · 중보기도 · 말씀묵상에 남긴 댓글을 모두 모은다 (collection group 조회, 본인 댓글만 읽힌다).
  /// 댓글이 달린 글의 제목(중보기도는 글쓴이 이름)은 한 번씩 읽어 붙이고, 읽을 수 없으면 비워 둔다. 지운 댓글은 뺀다.
  Future<List<MyComment>> mineAcrossChurch(String churchId) async {
    final uid = _auth.uid;
    final found = <MyComment>[];
    final titles = <String, Future<String>>{};

    Future<String> titleOf(DocumentReference<Json> ref, String field) =>
        titles.putIfAbsent(ref.path, () async {
          try {
            final d = await ref.get();
            final v = d.data()?[field] as String? ?? '';
            return v.length > 40 ? '${v.substring(0, 40)}…' : v;
          } catch (_) {
            return '';
          }
        });

    Future<void> collect(String group, String textField) async {
      final snap = await _db
          .collectionGroup(group)
          .where('authorId', isEqualTo: uid)
          .get();
      // 이 교회의 지우지 않은 댓글만 추린다 (지운 댓글이 많아도 글 제목은 필요한 글만 읽는다).
      final rows =
          <
            ({CommentTarget target, DocumentReference<Json> parent, Json data})
          >[];
      for (final d in snap.docs) {
        final data = d.data();
        final parts = d.reference.path.split('/');
        // churches/{교회}/{종류}/{글}/{group}/{댓글}
        if (parts.length != 6 || parts[1] != churchId) continue;
        if (data['deleted'] == true) continue;
        final target = switch (parts[2]) {
          'meetings' => CommentTarget.meeting,
          'prayers' => CommentTarget.prayer,
          'devotions' => CommentTarget.devotion,
          _ => null,
        };
        if (target == null) continue;
        rows.add((
          target: target,
          parent: d.reference.parent.parent!,
          data: data,
        ));
      }
      // 글 제목은 글마다 한 번씩, 한꺼번에 읽는다 (하나씩 차례로 읽으면 댓글이 많을 때 오래 걸린다).
      final pending = [
        for (final r in rows)
          titleOf(
            r.parent,
            // 중보기도는 내용 요약 대신 글쓴이 이름을 보인다.
            r.target == CommentTarget.prayer ? 'authorName' : 'title',
          ),
      ];
      final resolved = await Future.wait(pending);
      for (var i = 0; i < rows.length; i++) {
        final r = rows[i];
        found.add(
          MyComment(
            target: r.target,
            targetId: r.parent.id,
            text: (r.data[textField] ?? r.data['content']) as String? ?? '',
            targetTitle: resolved[i],
            date: toDate(r.data['createdAt'] ?? r.data['updatedAt']),
          ),
        );
      }
    }

    await Future.wait([
      collect('comments', 'text'),
      collect('reflections', 'text'),
    ]);
    return found;
  }
}
