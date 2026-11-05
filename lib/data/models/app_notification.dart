import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_codec.dart';

/// 알림 종류. [name]이 `users/{uid}/notifications` 문서의 `type`에 저장된다.
enum NotificationType {
  churchRejected,
  churchRemoved,

  /// 내가 만든 모임(승인 필요)에 누가 참여를 신청했다.
  meetingJoinRequest,

  /// 내 글(기도제목 · 말씀묵상 · 모임)에 누가 댓글을 달았다.
  postComment,

  /// 내 글에 누가 좋아요를 눌렀다.
  postLike,
  general,
}

/// 내 알림 한 건 (예: 교회 생성 요청이 거절되었어요).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.read,
    this.createdAt,
    this.hidden = false,
    this.churchId = '',
    this.meetingId = '',
    this.postKind = '',
    this.postId = '',
  });

  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final bool read;
  final DateTime? createdAt;

  /// 내 목록에서 숨긴 알림 (지우지 않고 표시만 남긴다).
  final bool hidden;

  /// 알림이 가리키는 교회와 모임 (모임 신청 알림에서 누르면 그 모임을 연다).
  final String churchId;
  final String meetingId;

  /// 댓글 · 좋아요 알림이 가리키는 글: 종류(`prayer` · `devotion` · `meeting`)와 글 아이디.
  final String postKind;
  final String postId;

  /// 누르면 갈 곳이 있는가.
  bool get hasTarget => meetingId.isNotEmpty || postId.isNotEmpty;

  /// 눌렀을 때 열 글의 종류와 아이디 (모임 신청 알림은 모임).
  (String, String) get target =>
      postId.isNotEmpty ? (postKind, postId) : ('meeting', meetingId);

  factory AppNotification.fromDoc(DocumentSnapshot<Json> doc) {
    final d = doc.data() ?? const {};
    return AppNotification(
      id: doc.id,
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      type: enumByName(
        NotificationType.values,
        d['type'],
        NotificationType.general,
      ),
      read: d['read'] as bool? ?? false,
      createdAt: toDate(d['createdAt']),
      hidden: d['hidden'] == true,
      churchId: d['churchId'] as String? ?? '',
      meetingId: d['meetingId'] as String? ?? '',
      postKind: d['postKind'] as String? ?? '',
      postId: d['postId'] as String? ?? '',
    );
  }
}
