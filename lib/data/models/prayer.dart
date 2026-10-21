import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_codec.dart';

enum PrayerVisibility { public, private }

class Prayer {
  const Prayer({
    required this.id,
    required this.authorId,
    required this.title,
    required this.content,
    required this.visibility,
    required this.deleted,
    this.departmentId,
    this.createdAt,
    this.deleteReason,
    this.deletedBy,
    this.lastResponseAt,
    this.responseSeenAt,
  });

  final String id;
  final String authorId;
  final String title;
  final String content;
  final PrayerVisibility visibility;
  final bool deleted;

  /// null이면 교회 전체 글, 값이 있으면 그 부서 전용 글.
  final String? departmentId;
  final DateTime? createdAt;
  final String? deleteReason;
  final String? deletedBy;
  final DateTime? lastResponseAt;
  final DateTime? responseSeenAt;

  bool get isPublic => visibility == PrayerVisibility.public;

  bool get hasUnreadResponse =>
      lastResponseAt != null &&
      (responseSeenAt == null || lastResponseAt!.isAfter(responseSeenAt!));

  factory Prayer.fromDoc(DocumentSnapshot<Json> doc) {
    final d = doc.data() ?? const {};
    return Prayer(
      id: doc.id,
      authorId: d['authorId'] as String? ?? '',
      title: d['title'] as String? ?? '',
      content: d['content'] as String? ?? '',
      visibility: enumByName(
        PrayerVisibility.values,
        d['visibility'],
        PrayerVisibility.private,
      ),
      deleted: d['deleted'] as bool? ?? false,
      departmentId: d['departmentId'] as String?,
      // 서버 시각이 아직 확정되지 않은 로컬 쓰기는 null이므로 현재 시각으로 대체한다.
      createdAt: toDate(d['createdAt']) ?? DateTime.now(),
      deleteReason: d['deleteReason'] as String?,
      deletedBy: d['deletedBy'] as String?,
      lastResponseAt: toDate(d['lastResponseAt']),
      responseSeenAt: toDate(d['responseSeenAt']),
    );
  }
}
