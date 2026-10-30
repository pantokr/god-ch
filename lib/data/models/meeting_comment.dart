import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_codec.dart';

/// 일정(모임)에 교인이 남긴 댓글 한 건. `churches/{id}/meetings/{모임}/comments/{댓글}`에 저장된다.
/// 지울 때는 지운 표시만 남기고 목록에는 나오지 않는다.
class MeetingComment {
  const MeetingComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.text,
    this.createdAt,
  });

  /// 글자 수 제한 (`firestore.rules`와 같다).
  static const maxLength = 500;

  final String id;
  final String authorId;
  final String authorName;
  final String text;
  final DateTime? createdAt;

  factory MeetingComment.fromDoc(DocumentSnapshot<Json> doc) {
    final d = doc.data() ?? const {};
    return MeetingComment(
      id: doc.id,
      authorId: d['authorId'] as String? ?? '',
      authorName: d['authorName'] as String? ?? '',
      text: d['text'] as String? ?? '',
      createdAt: toDate(d['createdAt']),
    );
  }
}
