import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/app_exception.dart';
import '../../../data/models/church_content.dart';

/// 유튜브 채널이나 재생목록의 영상을 자동으로 불러온다.
/// API 키 없이 공개 페이지에 실린 영상 목록(최근 순)을 읽는다.
class YoutubeFeed {
  YoutubeFeed._();

  /// 피드에서 온 영상의 id 머리말. 교회 글이 아니라 유튜브에서 바로 연다.
  static const idPrefix = 'yt:';

  static final _cache = <String, Future<List<ChurchContent>>>{};

  /// 채널이나 재생목록 주소의 최근 영상. 같은 주소는 앱을 켜 둔 동안 한 번만 읽는다.
  static Future<List<ChurchContent>> fetch(String url) {
    final key = url.trim();
    return _cache.putIfAbsent(key, () => _load(key)).catchError((Object e) {
      _cache.remove(key);
      throw e;
    });
  }

  static Future<List<ChurchContent>> _load(String url) async {
    final page = youtubeFeedTarget(url);
    if (page == null) throw const AppException('채널이나 재생목록 주소가 아닙니다.');
    final res = await http
        .get(
          page,
          headers: {'User-Agent': 'Mozilla/5.0', 'Accept-Language': 'ko'},
        )
        .timeout(const Duration(seconds: 15));
    final html = utf8.decode(res.bodyBytes, allowMalformed: true);
    final m = RegExp(
      r'ytInitialData\s*=\s*(\{.*?\});</script>',
      dotAll: true,
    ).firstMatch(html);
    if (res.statusCode != 200 || m == null) {
      throw const AppException('영상을 불러오지 못했습니다.');
    }
    final items = <ChurchContent>[];
    final seen = <String>{};
    void add(String? id, String? title) {
      if (id == null || title == null || !seen.add(id)) return;
      items.add(
        ChurchContent(
          id: '$idPrefix$id',
          kind: ContentKind.sermon,
          title: title,
          body: '',
          date: DateTime.now(),
          videoUrl: 'https://www.youtube.com/watch?v=$id',
        ),
      );
    }

    void walk(Object? o) {
      if (o is Map) {
        if (o['contentType'] == 'LOCKUP_CONTENT_TYPE_VIDEO') {
          final meta = (o['metadata'] as Map?)?['lockupMetadataViewModel'];
          add(
            o['contentId'] as String?,
            ((meta as Map?)?['title'] as Map?)?['content'] as String?,
          );
        }
        for (final k in const ['videoRenderer', 'playlistVideoRenderer']) {
          final r = o[k];
          if (r is Map && r['videoId'] is String && r['title'] is Map) {
            final t = r['title'] as Map;
            add(
              r['videoId'] as String,
              (t['simpleText'] as String?) ??
                  [for (final x in (t['runs'] as List? ?? const [])) x['text']]
                      .join(),
            );
          }
        }
        o.values.forEach(walk);
      } else if (o is List) {
        o.forEach(walk);
      }
    }

    walk(jsonDecode(m.group(1)!));
    if (items.isEmpty) throw const AppException('영상이 없습니다.');
    return items;
  }
}
