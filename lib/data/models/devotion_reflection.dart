import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_codec.dart';

/// 말씀묵상 한 편에 교인이 남기는 자기 글. 한 사람이 한 편에 한 개를 쓰고 고친다.
/// 문서 ID가 쓴 사람의 uid다 (`churches/{id}/devotions/{글}/reflections/{uid}`).
class DevotionReflection {
  const DevotionReflection({
    required this.authorId,
    required this.authorName,
    required this.text,
    this.updatedAt,
    this.deleted = false,
  });

  /// 쓴 사람의 uid (문서 ID와 같다).
  final String authorId;
  final String authorName;
  final String text;
  final DateTime? updatedAt;

  /// 지워진 글인가 (지우지 않고 표시만 남긴다).
  final bool deleted;

  /// 글 길이 제한. `firestore.rules`의 제한과 같아야 한다.
  static const maxLength = 1000;

  factory DevotionReflection.fromDoc(DocumentSnapshot<Json> doc) {
    final d = doc.data()!;
    return DevotionReflection(
      authorId: doc.id,
      authorName: d['authorName'] as String? ?? '',
      text: d['text'] as String? ?? '',
      updatedAt: toDate(d['updatedAt']),
      deleted: d['deleted'] == true,
    );
  }
}
