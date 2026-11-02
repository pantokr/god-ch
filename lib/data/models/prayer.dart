import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_codec.dart';

enum PrayerVisibility { public, private }

class Prayer {
  const Prayer({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.visibility,
    required this.deleted,
    this.affiliationId,
    this.views = 0,
    this.readBy = const [],
    this.createdAt,
    this.deleteReason,
    this.deletedBy,
    this.lastResponseAt,
    this.responseSeenAt,
  });

  final String id;
  final String authorId;

  /// 글쓴이 이름 (글을 쓸 때 함께 저장한다).
  final String authorName;
  final String content;
  final PrayerVisibility visibility;
  final bool deleted;

  /// null이면 교회 전체 글, 값이 있으면 그 소속 전용 글.
  final String? affiliationId;
  final int views;

  /// 이 글을 열어 읽은 사람들의 uid.
  final List<String> readBy;
  final DateTime? createdAt;
  final String? deleteReason;
  final String? deletedBy;
  final DateTime? lastResponseAt;
  final DateTime? responseSeenAt;

  /// [uid]가 이 글을 읽었는가. 내가 쓴 글은 읽은 것으로 본다.
  bool readByUser(String uid) => authorId == uid || readBy.contains(uid);

  bool get isPublic => visibility == PrayerVisibility.public;

  bool get hasUnreadResponse =>
      lastResponseAt != null &&
      (responseSeenAt == null || lastResponseAt!.isAfter(responseSeenAt!));

  factory Prayer.fromDoc(DocumentSnapshot<Json> doc) {
    final d = doc.data() ?? const {};
    return Prayer(
      id: doc.id,
      authorId: d['authorId'] as String? ?? '',
      authorName: d['authorName'] as String? ?? '',
      content: d['content'] as String? ?? '',
      visibility: enumByName(
        PrayerVisibility.values,
        d['visibility'],
        PrayerVisibility.private,
      ),
      deleted: d['deleted'] as bool? ?? false,
      affiliationId: d['affiliationId'] as String?,
      views: (d['views'] as num?)?.toInt() ?? 0,
      readBy: List<String>.from(d['readBy'] as List? ?? const []),
      // 서버 시각이 아직 확정되지 않은 로컬 쓰기는 null이므로 현재 시각으로 대체한다.
      createdAt: toDate(d['createdAt']) ?? DateTime.now(),
      deleteReason: d['deleteReason'] as String?,
      deletedBy: d['deletedBy'] as String?,
      lastResponseAt: toDate(d['lastResponseAt']),
      responseSeenAt: toDate(d['responseSeenAt']),
    );
  }
}
