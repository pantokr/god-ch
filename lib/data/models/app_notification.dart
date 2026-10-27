import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_codec.dart';

/// 알림 종류. [name]이 `users/{uid}/notifications` 문서의 `type`에 저장된다.
enum NotificationType { churchRejected, churchRemoved, general }

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
  });

  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final bool read;
  final DateTime? createdAt;

  /// 내 목록에서 숨긴 알림 (지우지 않고 표시만 남긴다).
  final bool hidden;

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
    );
  }
}
