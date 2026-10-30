import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/app_exception.dart';
import '../../../data/firestore_codec.dart';
import '../../../data/firestore_paths.dart';
import '../../../data/models/devotion_reflection.dart';
import '../../auth/data/auth_repository.dart';

/// 말씀묵상 글의 댓글을 읽고 쓴다. 읽기는 승인된 교인 모두, 쓰기는 댓글 권한이 있는 교인이고
/// 지우기는 본인 댓글 또는 타인 댓글 삭제 권한이 있는 사람이다 (`firestore.rules`가 강제한다).
class ReflectionRepository {
  ReflectionRepository(FirebaseFirestore db, this._auth)
    : _paths = FirestorePaths(db);

  final FirestorePaths _paths;
  final AuthRepository _auth;

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
    return _col(churchId, devotionId).add({
      'authorId': _auth.uid,
      'authorName': authorName,
      'text': t,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 댓글을 지운 것으로 표시한다 (문서는 남긴다). 본인 댓글이거나 타인 댓글 삭제 권한이 있어야 한다.
  Future<void> delete(String churchId, String devotionId, String commentId) =>
      _col(churchId, devotionId).doc(commentId).update({
        'deleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': _auth.uid,
      });
}
