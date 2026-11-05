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
    this.parentId,
    this.deleted = false,
    this.editedAt,
  });

  /// 글자 수 제한 (`firestore.rules`와 같다).
  static const maxLength = 500;

  final String id;
  final String authorId;
  final String authorName;
  final String text;
  final DateTime? createdAt;

  /// 답글이면 바로 윗 댓글의 id, 최상위 댓글이면 null.
  final String? parentId;

  /// 지운 댓글인가 (기록은 남는다). 답글이 달려 있으면 자리만 남겨 보여준다.
  final bool deleted;

  /// 고친 시각 (고친 적이 없으면 null).
  final DateTime? editedAt;

  factory MeetingComment.fromDoc(DocumentSnapshot<Json> doc) {
    final d = doc.data() ?? const {};
    return MeetingComment(
      id: doc.id,
      authorId: d['authorId'] as String? ?? '',
      authorName: d['authorName'] as String? ?? '',
      text: d['text'] as String? ?? '',
      createdAt: toDate(d['createdAt']),
      parentId: d['parentId'] as String?,
      deleted: d['deleted'] == true,
      editedAt: toDate(d['editedAt']),
    );
  }
}
