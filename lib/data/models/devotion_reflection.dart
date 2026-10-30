import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_codec.dart';

/// 말씀묵상 한 편에 교인이 남기는 댓글 한 건. 한 사람이 여러 개를 달 수 있다.
/// `churches/{id}/devotions/{글}/reflections/{댓글}`에 저장된다. (예전 글은 문서 ID가 쓴 사람의 uid다.)
class DevotionReflection {
  const DevotionReflection({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.text,
    this.updatedAt,
    this.deleted = false,
  });

  /// 댓글 문서 ID.
  final String id;

  /// 쓴 사람의 uid.
  final String authorId;
  final String authorName;
  final String text;

  /// 댓글을 쓴 시각.
  final DateTime? updatedAt;

  /// 지워진 글인가 (지우지 않고 표시만 남긴다).
  final bool deleted;

  /// 글 길이 제한. `firestore.rules`의 제한과 같아야 한다.
  static const maxLength = 1000;

  factory DevotionReflection.fromDoc(DocumentSnapshot<Json> doc) {
    final d = doc.data()!;
    return DevotionReflection(
      id: doc.id,
      authorId: d['authorId'] as String? ?? doc.id,
      authorName: d['authorName'] as String? ?? '',
      text: d['text'] as String? ?? '',
      updatedAt: toDate(d['updatedAt']),
      deleted: d['deleted'] == true,
    );
  }
}
