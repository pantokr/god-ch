import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_codec.dart';

/// 교회 메인 페이지를 이루는 콘텐츠 종류. [collection]이 `churches/{id}/` 아래 컬렉션 이름이자
/// 주소의 한 부분이다. 새 종류를 더하면 `firestore.rules`의 목록도 함께 고친다.
enum ContentKind {
  notice('notices', '공지사항'),
  event('events', '일정'),
  photo('photos', '사진첩'),
  sermon('sermons', '설교영상'),
  devotion('devotions', '말씀묵상');

  const ContentKind(this.collection, this.label);

  final String collection;
  final String label;

  /// 글을 영역으로 나눌 수 있는 종류 (공지 · 사진첩 · 설교영상).
  /// 일정은 날짜로, 말씀묵상은 템플릿 하나로 보여주므로 영역이 없다.
  bool get hasAreas =>
      this == ContentKind.notice ||
      this == ContentKind.photo ||
      this == ContentKind.sermon;

  static ContentKind? fromPath(String path) {
    for (final k in values) {
      if (k.collection == path) return k;
    }
    return null;
  }
}

/// 글을 나누는 영역 하나 (예: 공지사항 안의 "행사", "홍보"). 한 종류 안에서 이름이 겹치지 않는다.
/// 영역은 비어 있어야만 지울 수 있고, 글은 다른 영역으로 옮길 수 있다.
/// 글에는 영역의 이름이 [ChurchContent.category]로 저장된다 (비어 있으면 영역 없음).
class ContentArea {
  const ContentArea({required this.kind, required this.name, this.id});

  /// 영역을 따로 만들지 않고 글에만 적혀 있던 이름이면 null.
  final String? id;
  final ContentKind kind;
  final String name;

  static ContentArea? fromDoc(DocumentSnapshot<Json> doc) {
    final d = doc.data() ?? const {};
    final kind = ContentKind.fromPath(d['kind'] as String? ?? '');
    final name = d['name'] as String? ?? '';
    if (kind == null || name.isEmpty) return null;
    return ContentArea(id: doc.id, kind: kind, name: name);
  }
}

/// 공지·일정·사진첩·설교·말씀묵상 한 건. 종류마다 쓰는 필드가 조금씩 다르다.
/// - 공지: 제목, 본문, 썸네일(첫 이미지, 4:3 고정), 캐러셀 배경(둘째 이미지, 가로)
/// - 일정: 제목, 본문(장소·설명), [date]가 일정 날짜
/// - 사진첩: 제목, 본문, 사진 여러 장
/// - 설교영상: 제목, 본문, [videoUrl](유튜브 주소), [date]가 설교한 날
/// - 말씀묵상: 제목(성경 구절), 본문(묵상), [date]가 묵상 날짜
class ChurchContent {
  const ChurchContent({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.date,
    this.imageUrls = const [],
    this.videoUrl = '',
    this.category = '',
    this.createdAt,
    this.deleted = false,
  });

  final String id;
  final ContentKind kind;
  final String title;
  final String body;

  /// 일정·설교·묵상의 날짜. 공지와 사진첩은 올린 날짜가 들어간다.
  final DateTime date;
  final List<String> imageUrls;

  /// 분류 글자 수 제한 (`firestore.rules`와 같아야 한다).
  static const maxCategoryLength = 20;

  final String videoUrl;

  /// 글의 분류 (예: 행사, 홍보). 구조가 분류별로 골라 보여줄 때 쓴다. 비어 있으면 분류 없음.
  final String category;
  final DateTime? createdAt;

  /// 지워진 글인가. 글은 지우지 않고 표시만 남기며, 목록에는 나오지 않는다.
  final bool deleted;

  String? get thumbnail {
    if (imageUrls.isNotEmpty) return imageUrls.first;
    return youtubeThumbnail(videoUrl);
  }

  /// 교회 글이 아니라 유튜브 채널·재생목록에서 자동으로 가져온 영상인가. 올린 날짜를 알 수 없다.
  bool get fromFeed => id.startsWith('yt:');

  /// 공지의 가로 배경 이미지 (두 번째 이미지). 없으면 null.
  String? get background => imageUrls.length > 1 ? imageUrls[1] : null;

  factory ChurchContent.fromDoc(ContentKind kind, DocumentSnapshot<Json> doc) {
    final d = doc.data() ?? const {};
    final created = toDate(d['createdAt']);
    return ChurchContent(
      id: doc.id,
      kind: kind,
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      date: toDate(d['date']) ?? created ?? DateTime.now(),
      imageUrls: List<String>.from(d['imageUrls'] as List? ?? const []),
      videoUrl: d['videoUrl'] as String? ?? '',
      category: d['category'] as String? ?? '',
      createdAt: created,
      deleted: d['deleted'] == true,
    );
  }
}

/// 유튜브 주소에서 영상 ID를 꺼낸다. 유튜브 주소가 아니면 null.
String? youtubeId(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return null;
  final host = uri.host.replaceFirst('www.', '').replaceFirst('m.', '');
  if (host == 'youtu.be') {
    return uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
  }
  if (host == 'youtube.com') {
    if (uri.queryParameters['v'] case final v?) return v;
    final segs = uri.pathSegments;
    if (segs.length >= 2 && (segs[0] == 'embed' || segs[0] == 'shorts')) {
      return segs[1];
    }
  }
  return null;
}

/// 채널이나 재생목록 주소를 영상 목록이 있는 페이지 주소로 바꾼다. 그런 주소가 아니면 null.
Uri? youtubeFeedTarget(String url) =>
    youtubePlaylistTarget(url) ?? youtubeChannelTarget(url);

/// 재생목록 주소(`list=` 가 있는 주소)를 영상 목록 페이지 주소로 바꾼다. 아니면 null.
Uri? youtubePlaylistTarget(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return null;
  final host = uri.host.replaceFirst('www.', '').replaceFirst('m.', '');
  if (host != 'youtube.com') return null;
  final list = uri.queryParameters['list'];
  if (list == null || list.isEmpty) return null;
  return Uri.https('www.youtube.com', '/playlist', {'list': list});
}

/// 채널 주소(@이름, /channel/, /c/, /user/)를 영상 목록 페이지 주소로 바꾼다. 아니면 null.
Uri? youtubeChannelTarget(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return null;
  final host = uri.host.replaceFirst('www.', '').replaceFirst('m.', '');
  if (host != 'youtube.com') return null;
  if (uri.queryParameters['list']?.isNotEmpty ?? false) return null;
  final segs = uri.pathSegments;
  if (segs.isEmpty) return null;
  if (segs[0].startsWith('@')) {
    return Uri.https('www.youtube.com', '/${segs[0]}/videos');
  }
  if (segs.length >= 2 && const {'channel', 'c', 'user'}.contains(segs[0])) {
    return Uri.https('www.youtube.com', '/${segs[0]}/${segs[1]}/videos');
  }
  return null;
}

String? youtubeThumbnail(String url) {
  final id = youtubeId(url);
  return id == null ? null : 'https://img.youtube.com/vi/$id/hqdefault.jpg';
}

/// 썸네일은 항상 4:3 (가로:세로) 비율로 보여 준다.
const kThumbnailAspect = 4 / 3;
