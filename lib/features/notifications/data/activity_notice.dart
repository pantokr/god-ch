import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../data/models/app_notification.dart';

/// 내 글에 댓글이 달리거나 좋아요가 눌렸을 때 글쓴이에게 보내는 알림.
/// 댓글 · 좋아요와 같은 묶음(batch)으로 `users/{글쓴이}/notifications`에 쓴다.
/// 내가 내 글에 한 것은 보내지 않는다. 쓸 수 있는 조건은 `firestore.rules`가 강제한다.
class ActivityNotice {
  const ActivityNotice._();

  /// 알림이 가리키는 글 종류 (`firestore.rules`와 같아야 한다).
  static const prayer = 'prayer';
  static const devotion = 'devotion';
  static const meeting = 'meeting';

  /// 묶음에 알림 한 건을 더한다. [authorId]가 나 자신이면 아무것도 하지 않는다.
  static void add(
    WriteBatch batch,
    FirebaseFirestore db, {
    required String me,
    required String authorId,
    required String churchId,
    required String kind,
    required String postId,
    required String postTitle,
    required String actorName,
    required bool comment,
  }) {
    if (authorId.isEmpty || authorId == me) return;
    final who = actorName.trim().isEmpty ? '누군가' : actorName.trim();
    final title = postTitle.trim().replaceAll(RegExp(r'\s+'), ' ');
    final short = title.length > 30 ? '${title.substring(0, 30)}…' : title;
    batch.set(
      db.collection('users').doc(authorId).collection('notifications').doc(),
      {
        'type':
            (comment ? NotificationType.postComment : NotificationType.postLike)
                .name,
        'title': '${comment ? '댓글' : '좋아요'} · $short',
        'body': comment ? '$who님이 댓글을 남겼어요.' : '$who님이 좋아해요.',
        'read': false,
        'churchId': churchId,
        'postKind': kind,
        'postId': postId,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
  }
}
