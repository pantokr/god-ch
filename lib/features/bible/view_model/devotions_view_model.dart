import '../../../core/mvvm/view_model.dart';
import '../../../data/models/affiliation.dart';

import 'dart:async';

import '../../../data/models/church_content.dart';
import '../../../data/models/devotion_settings.dart';
import '../../home/data/content_repository.dart';

/// 목록 정렬 기준.
enum DevotionSort {
  latest('최신순'),
  views('조회순'),
  likes('좋아요순');

  const DevotionSort(this.label);

  final String label;
}

/// 성경(말씀묵상) 화면: 최근 말씀 글 목록, 검색 · 정렬, 교역자의 추가 · 수정 · 삭제.
/// 스트림은 한 번만 만든다. 검색 · 정렬은 읽어 온 글에서 화면이 바로 거른다.
class DevotionsViewModel extends ViewModel {
  DevotionsViewModel(
    this._repo,
    this.churchId, {
    this.authorName = '',
    this.authorPhotoUrl = '',
    this.affiliations = const Stream.empty(),
    bool includePrivate = false,
  }) : items = _repo.latest(
         churchId,
         limit: 100,
         includePrivate: includePrivate,
       ) {
    _settingsSub = _repo.settings(churchId).listen((v) {
      settings = v;
      notifyListeners();
    }, onError: (_) {});
  }

  late final StreamSubscription<DevotionSettings> _settingsSub;

  /// 교회가 정한 말씀묵상 운영 설정 (좋아요 · 댓글 · 조회수 · 글쓴이). 정한 적 없으면 모두 허용 · 공개.
  DevotionSettings settings = DevotionSettings.standard;

  @override
  void dispose() {
    _settingsSub.cancel();
    super.dispose();
  }

  final ContentRepository _repo;
  final String churchId;

  /// 새 글에 남기는 글쓴이 (로그인한 교인).
  final String authorName;
  final String authorPhotoUrl;
  final Stream<List<ChurchContent>> items;

  /// 분류에 쓰는 교회의 소속들.
  final Stream<List<Affiliation>> affiliations;

  /// 지금 고른 소속. null이면 모든 글을 본다.
  String? _affiliationId;
  String? get affiliationId => _affiliationId;

  void setAffiliation(String? id) {
    if (_affiliationId == id) return;
    _affiliationId = id;
    notifyListeners();
  }

  String _query = '';
  DevotionSort _sort = DevotionSort.latest;

  String get query => _query;
  DevotionSort get sort => _sort;

  void setQuery(String value) {
    _query = value.trim().toLowerCase();
    notifyListeners();
  }

  void setSort(DevotionSort value) {
    if (_sort == value) return;
    _sort = value;
    notifyListeners();
  }

  /// 검색어(제목 · 말씀 · 묵상 · 글쓴이)에 맞는 글을 정렬 기준대로 돌려준다.
  List<ChurchContent> apply(List<ChurchContent> all) {
    final list = [
      for (final c in all)
        if ((_affiliationId == null || c.affiliationId == _affiliationId) &&
            (_query.isEmpty ||
                c.title.toLowerCase().contains(_query) ||
                c.body.toLowerCase().contains(_query) ||
                c.meditation.toLowerCase().contains(_query) ||
                c.authorName.toLowerCase().contains(_query)))
          c,
    ];
    switch (_sort) {
      case DevotionSort.latest:
        break; // 읽어 올 때 이미 날짜 최신순이다.
      case DevotionSort.views:
        list.sort((a, b) => b.views.compareTo(a.views));
      case DevotionSort.likes:
        list.sort((a, b) => b.likes.compareTo(a.likes));
    }
    return list;
  }

  /// 최근 [within](기본 7일) 안에 글을 쓴 사람들 (중복 없이 최신 글 순서, 이름이 없는 글은 뺀다).
  /// 몇 명을 보여 줄지는 화면이 정한다.
  static List<ChurchContent> recentAuthors(
    List<ChurchContent> all, {
    Duration within = const Duration(days: 7),
    DateTime? now,
  }) {
    final since = (now ?? DateTime.now()).subtract(within);
    final seen = <String>{};
    final out = <ChurchContent>[];
    for (final c in all) {
      if ((c.createdAt ?? c.date).isBefore(since)) continue;
      final key = c.authorId.isNotEmpty ? c.authorId : c.authorName;
      if (c.authorName.isEmpty || !seen.add(key)) continue;
      out.add(c);
    }
    return out;
  }

  Future<bool> save({
    String? id,
    required String title,
    required String body,
    required String meditation,
    required DateTime date,
    String? affiliationId,
    bool isPrivate = false,
  }) => run(
    () => _repo.save(
      churchId,
      id: id,
      title: title,
      body: body,
      meditation: meditation,
      date: date,
      authorName: authorName,
      authorPhotoUrl: authorPhotoUrl,
      affiliationId: affiliationId,
      isPrivate: isPrivate,
    ),
  );

  Future<bool> delete(String id) => run(() => _repo.delete(churchId, id));
}
