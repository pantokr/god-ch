import '../../../core/mvvm/view_model.dart';
import '../../../data/models/affiliation.dart';

import 'dart:async';

import '../../../data/models/church_content.dart';
import '../../../data/models/devotion_settings.dart';
import '../../home/data/content_repository.dart';

/// 목록 정렬 기준.
enum DevotionSort {
  latest('최신순'),
  oldest('오래된순'),
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
    this.readerId = '',
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

  /// 읽음 여부를 가릴 교인 (로그인한 교인).
  final String readerId;
  final Stream<List<ChurchContent>> items;

  /// 분류에 쓰는 교회의 소속들.
  final Stream<List<Affiliation>> affiliations;

  String _query = '';
  DevotionSort _sort = DevotionSort.latest;
  bool _hideRead = false;

  String get query => _query;
  DevotionSort get sort => _sort;

  /// 이미 읽은 글을 빼고 보는가.
  bool get hideRead => _hideRead;

  void toggleHideRead() {
    _hideRead = !_hideRead;
    notifyListeners();
  }

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
  /// [affiliationId]가 있으면 교회 전체 글과 그 소속의 글만, null이면(전체) 모든 글을 본다.
  List<ChurchContent> apply(List<ChurchContent> all, {String? affiliationId}) =>
      filter(
        all,
        query: _query,
        sort: _sort,
        affiliationId: affiliationId,
        hideReadBy: _hideRead ? readerId : null,
      );

  /// [apply]의 계산 부분 (내 활동 같은 다른 화면도 같은 검색 · 정렬을 쓴다). [query]는 소문자로 다듬은 검색어.
  static List<ChurchContent> filter(
    List<ChurchContent> all, {
    String query = '',
    DevotionSort sort = DevotionSort.latest,
    String? affiliationId,
    String? hideReadBy,
  }) {
    final list = [
      for (final c in all)
        if ((hideReadBy == null ||
                hideReadBy.isEmpty ||
                !c.readBy.contains(hideReadBy)) &&
            (affiliationId == null ||
                c.affiliationId == null ||
                c.affiliationId == affiliationId) &&
            (query.isEmpty ||
                c.title.toLowerCase().contains(query) ||
                c.body.toLowerCase().contains(query) ||
                c.meditation.toLowerCase().contains(query) ||
                c.authorName.toLowerCase().contains(query)))
          c,
    ];
    switch (sort) {
      case DevotionSort.latest:
        break; // 읽어 올 때 이미 날짜 최신순이다.
      case DevotionSort.oldest:
        return list.reversed.toList();
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
