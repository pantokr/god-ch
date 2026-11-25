import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/widgets/anonymous_author.dart' show anonymousName;
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
    this.title = '',
    this.affiliationId,
    this.authorHidden = false,
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

  /// 제목 길이 제한 (`firestore.rules`와 일치).
  static const maxTitle = 30;

  /// 제목. 제목을 받기 전에 쓴 글은 비어 있다.
  final String title;
  final String content;
  final PrayerVisibility visibility;
  final bool deleted;

  /// null이면 교회 전체 글, 값이 있으면 그 소속 전용 글.
  final String? affiliationId;

  /// 글쓴이가 작성자를 비공개(익명)로 한 글인가. 교회가 허용한 경우에만 쓸 수 있다.
  final bool authorHidden;
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

  /// 글쓴이가 [viewerId]에게 가려지는가: 작성자 비공개 글은 본인과 교역자 이상([staff])만 글쓴이를 본다.
  /// 비공개는 글에 저장된 값을 따른다 (교회가 나중에 허용을 꺼도 이미 비공개로 한 글은 그대로 가려진다).
  bool hidesAuthorFrom(String viewerId, {required bool staff}) =>
      authorHidden && authorId != viewerId && !staff;

  /// 글쓴이 줄에 보이는 이름: 가려지면 "익명", 본인과 교역자가 작성자 비공개 글을 보면 이름 뒤에 "(비공개)"가 붙는다.
  String authorLabel(String viewerId, {required bool staff}) {
    if (hidesAuthorFrom(viewerId, staff: staff)) return anonymousName;
    final name = authorName.isEmpty ? '이름 없음' : authorName;
    return authorHidden ? '$name (비공개)' : name;
  }

  bool get hasUnreadResponse =>
      lastResponseAt != null &&
      (responseSeenAt == null || lastResponseAt!.isAfter(responseSeenAt!));

  factory Prayer.fromDoc(DocumentSnapshot<Json> doc) {
    final d = doc.data() ?? const {};
    return Prayer(
      id: doc.id,
      authorId: d['authorId'] as String? ?? '',
      authorName: d['authorName'] as String? ?? '',
      title: d['title'] as String? ?? '',
      content: d['content'] as String? ?? '',
      visibility: enumByName(
        PrayerVisibility.values,
        d['visibility'],
        PrayerVisibility.private,
      ),
      deleted: d['deleted'] as bool? ?? false,
      affiliationId: d['affiliationId'] as String?,
      authorHidden: d['authorHidden'] == true,
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
