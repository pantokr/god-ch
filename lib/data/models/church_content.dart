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

  static ContentKind? fromPath(String path) {
    for (final k in values) {
      if (k.collection == path) return k;
    }
    return null;
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
  final String videoUrl;
  final DateTime? createdAt;

  /// 지워진 글인가. 글은 지우지 않고 표시만 남기며, 목록에는 나오지 않는다.
  final bool deleted;

  String? get thumbnail {
    if (imageUrls.isNotEmpty) return imageUrls.first;
    return youtubeThumbnail(videoUrl);
  }

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

String? youtubeThumbnail(String url) {
  final id = youtubeId(url);
  return id == null ? null : 'https://img.youtube.com/vi/$id/hqdefault.jpg';
}

/// 썸네일은 항상 4:3 (가로:세로) 비율로 보여 준다.
const kThumbnailAspect = 4 / 3;
