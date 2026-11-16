import '../bible_reference.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/widgets/anonymous_author.dart' show anonymousName;
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

/// 말씀묵상 글에 함께 담기는 말씀 · 묵상 한 벌. 첫 벌은 글의 title · body · meditation에 있고,
/// 둘째부터는 [ChurchContent.extras]에 담긴다 (한 글에 최대 [ChurchContent.maxPassages]벌).
class DevotionPassage {
  const DevotionPassage({
    required String title,
    required this.body,
    required this.meditation,
  })
    // ignore: prefer_initializing_formals
    : _title = title;

  /// 성경 구절 이름. 저장된 값은 그대로 두고 보여 줄 때 개인 설정(전체 이름 · 줄임말)에 맞춘다.
  String get title => normalizeVerseTitle(_title);
  final String _title;

  /// 말씀 본문.
  final String body;

  /// 이 구절에 대한 묵상.
  final String meditation;

  Map<String, String> toMap() => {
    'title': _title.trim(),
    'body': body.trim(),
    'meditation': meditation.trim(),
  };

  factory DevotionPassage.fromMap(Map<String, dynamic> m) => DevotionPassage(
    title: m['title'] as String? ?? '',
    body: m['body'] as String? ?? '',
    meditation: m['meditation'] as String? ?? '',
  );
}

/// 말씀묵상 한 건: 제목(성경 구절), 본문(말씀), [meditation](묵상 글), [date]가 묵상 날짜.
/// 조회수([views])와 좋아요([likedBy]: 누른 사람의 uid들)가 함께 저장된다.
class ChurchContent {
  const ChurchContent({
    required this.id,
    required this.kind,
    required String title,
    required this.body,
    required this.date,
    this.meditation = '',
    this.extras = const [],
    this.views = 0,
    this.likedBy = const [],
    this.readBy = const [],
    this.visibility = 'public',
    this.authorId = '',
    this.authorName = '',
    this.authorPhotoUrl = '',
    this.affiliationId,
    this.authorHidden = false,
    this.createdAt,
    this.deleted = false,
  })
    // ignore: prefer_initializing_formals
    : _title = title;

  final String id;
  final ContentKind kind;

  /// 성경 구절 이름. 저장된 값은 그대로 두고 보여 줄 때 개인 설정(전체 이름 · 줄임말)에 맞춘다.
  String get title => normalizeVerseTitle(_title);
  final String _title;
  final String body;
  final DateTime date;

  /// 말씀에 대한 묵상 글 (교역자가 쓴다).
  final String meditation;

  /// 첫 벌 다음에 더해진 말씀 · 묵상 (최대 [maxPassages] - 1벌).
  final List<DevotionPassage> extras;

  /// 한 글에 담을 수 있는 말씀 · 묵상의 수. `firestore.rules`의 제한과 같아야 한다.
  static const maxPassages = 10;

  /// 이 글의 말씀 · 묵상 전부 (첫 벌 + 더해진 것들).
  List<DevotionPassage> get passages => [
    DevotionPassage(title: title, body: body, meditation: meditation),
    ...extras,
  ];

  /// 묵상 최소 글자 수. `firestore.rules`의 제한과 같아야 한다.
  static const minMeditation = 10;
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

  /// 글쓴이가 작성자를 비공개(익명)로 한 글인가. 교회가 허용한 경우에만 쓸 수 있다.
  final bool authorHidden;

  /// 글쓴이가 [viewerId]에게 가려지는가: 작성자 비공개 글은 본인과 교역자 이상([staff])만 글쓴이를 본다.
  /// 비공개는 글에 저장된 값을 따른다 (교회가 나중에 허용을 꺼도 이미 비공개로 한 글은 그대로 가려진다).
  bool hidesAuthorFrom(String viewerId, {required bool staff}) =>
      authorHidden && authorId != viewerId && !staff;

  /// 글쓴이 줄에 보이는 이름: 가려지면 "익명", 본인과 교역자가 작성자 비공개 글을 보면 이름 뒤에 "(비공개)"가 붙는다.
  String authorLabel(String viewerId, {required bool staff}) {
    if (hidesAuthorFrom(viewerId, staff: staff)) return anonymousName;
    final name = authorName.isEmpty ? '' : authorName;
    return authorHidden ? '$name (비공개)' : name;
  }

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
      extras: [
        for (final e in d['extras'] as List? ?? const [])
          if (e is Map) DevotionPassage.fromMap(Map<String, dynamic>.from(e)),
      ],
      views: (d['views'] as num?)?.toInt() ?? 0,
      likedBy: List<String>.from(d['likedBy'] as List? ?? const []),
      readBy: List<String>.from(d['readBy'] as List? ?? const []),
      visibility: d['visibility'] == 'private' ? 'private' : 'public',
      authorId: d['createdBy'] as String? ?? '',
      authorName: d['authorName'] as String? ?? '',
      authorPhotoUrl: d['authorPhotoUrl'] as String? ?? '',
      affiliationId: d['affiliationId'] as String?,
      authorHidden: d['authorHidden'] == true,
      createdAt: created,
      deleted: d['deleted'] == true,
    );
  }
}
