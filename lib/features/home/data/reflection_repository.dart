import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/app_exception.dart';
import '../../../data/firestore_codec.dart';
import '../../../data/firestore_paths.dart';
import '../../../data/models/devotion_reflection.dart';
import '../../auth/data/auth_repository.dart';

/// 말씀묵상 글에 교인이 남기는 자기 글을 읽고 쓴다.
/// 읽기는 승인된 교인 모두, 쓰기는 본인 글만 (삭제는 교역자도) 가능하다 (`firestore.rules`가 강제한다).
class ReflectionRepository {
  ReflectionRepository(FirebaseFirestore db, this._auth)
    : _paths = FirestorePaths(db);

  final FirestorePaths _paths;
  final AuthRepository _auth;

  CollectionReference<Json> _col(String churchId, String devotionId) => _paths
      .contents(churchId, 'devotions')
      .doc(devotionId)
      .collection('reflections');

  /// 최근에 쓰거나 고친 순. 쓴 사람 수가 많아도 [limit]까지만 읽는다.
  Stream<List<DevotionReflection>> latest(
    String churchId,
    String devotionId, {
    int limit = 30,
  }) => _col(churchId, devotionId)
      .orderBy('updatedAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(DevotionReflection.fromDoc).toList());

  /// 내 글을 처음 쓰거나 고친다.
  Future<void> saveMine(
    String churchId,
    String devotionId, {
    required String authorName,
    required String text,
  }) {
    final t = text.trim();
    if (t.isEmpty) throw const AppException('글을 입력해 주세요.');
    if (t.length > DevotionReflection.maxLength) {
      throw AppException('글은 ${DevotionReflection.maxLength}자까지 쓸 수 있어요.');
    }
    return _col(churchId, devotionId).doc(_auth.uid).set({
      'authorId': _auth.uid,
      'authorName': authorName,
      'text': t,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 글을 지운다. 본인 글이거나 교역자·교회 운영자만 가능하다.
  Future<void> delete(String churchId, String devotionId, String authorId) =>
      _col(churchId, devotionId).doc(authorId).delete();
}
