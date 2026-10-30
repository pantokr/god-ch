import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_codec.dart';

/// 교회가 올리는 글의 종류. [collection]이 `churches/{id}/` 아래 컬렉션 이름이다.
/// 지금은 말씀묵상(성경)뿐이다. 새 종류를 더하면 `firestore.rules`도 함께 고친다.
enum ContentKind {
  devotion('devotions', '말씀묵상');

  const ContentKind(this.collection, this.label);

  final String collection;
  final String label;

  static ContentKind? fromPath(String path) {
    for (final k in values) {
      if (k.collection == path) return k;
    }
    return null;
  }
}

/// 말씀묵상 한 건: 제목(성경 구절), 본문(말씀), [meditation](묵상 글), [date]가 묵상 날짜.
/// 조회수([views])와 좋아요([likedBy]: 누른 사람의 uid들)가 함께 저장된다.
class ChurchContent {
  const ChurchContent({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.date,
    this.meditation = '',
    this.views = 0,
    this.likedBy = const [],
    this.readBy = const [],
    this.visibility = 'public',
    this.authorId = '',
    this.authorName = '',
    this.authorPhotoUrl = '',
    this.affiliationId,
    this.createdAt,
    this.deleted = false,
  });

  final String id;
  final ContentKind kind;
  final String title;
  final String body;
  final DateTime date;

  /// 말씀에 대한 묵상 글 (교역자가 쓴다).
  final String meditation;
  final int views;
  final List<String> likedBy;

  /// 글을 열어 본 사람의 uid들 (목록의 읽음 표시에 쓴다).
  final List<String> readBy;

  /// 'public'(교인 모두) 또는 'private'(비공개: 말씀묵상 비공개 조회 권한이 있는 사람만).
  final String visibility;

  bool get isPrivate => visibility == 'private';

  /// 글쓴이. 이름과 프로필 사진 주소는 글을 쓸 때 함께 저장한다.
  final String authorId;
  final String authorName;
  final String authorPhotoUrl;

  /// 글을 분류한 소속. 없으면 교회 전체다.
  final String? affiliationId;
  final DateTime? createdAt;

  int get likes => likedBy.length;

  /// 지워진 글인가. 글은 지우지 않고 표시만 남기며, 목록에는 나오지 않는다.
  final bool deleted;

  factory ChurchContent.fromDoc(ContentKind kind, DocumentSnapshot<Json> doc) {
    final d = doc.data() ?? const {};
    final created = toDate(d['createdAt']);
    return ChurchContent(
      id: doc.id,
      kind: kind,
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      date: toDate(d['date']) ?? created ?? DateTime.now(),
      meditation: d['meditation'] as String? ?? '',
      views: (d['views'] as num?)?.toInt() ?? 0,
      likedBy: List<String>.from(d['likedBy'] as List? ?? const []),
      readBy: List<String>.from(d['readBy'] as List? ?? const []),
      visibility: d['visibility'] == 'private' ? 'private' : 'public',
      authorId: d['createdBy'] as String? ?? '',
      authorName: d['authorName'] as String? ?? '',
      authorPhotoUrl: d['authorPhotoUrl'] as String? ?? '',
      affiliationId: d['affiliationId'] as String?,
      createdAt: created,
      deleted: d['deleted'] == true,
    );
  }
}
