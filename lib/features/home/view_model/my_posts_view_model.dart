import 'dart:async';

import '../../../core/mvvm/view_model.dart';
import '../../../data/models/church_content.dart';
import '../../../data/models/my_comment.dart';
import '../../../data/models/prayer.dart';
import '../../prayers/data/prayer_repository.dart';
import '../data/content_repository.dart';
import '../data/reflection_repository.dart';

/// 내가 쓴 것 모아 보기의 종류.
enum MyPostFilter {
  prayer('중보기도'),
  devotion('말씀묵상'),
  comment('내 댓글');

  const MyPostFilter(this.label);

  final String label;
}

/// 내가 쓴 것 정렬.
enum MyPostSort {
  latest('최신순'),
  oldest('오래된순'),
  views('조회순'),
  likes('좋아요순');

  const MyPostSort(this.label);

  final String label;
}

/// 내 활동의 "내가 쓴 것": 중보기도, 내가 올린 말씀묵상, 내가 남긴 댓글을 종류별로 본다.
/// 스트림은 한 번만 만들고, 정렬은 화면이 바로 한다. 댓글은 처음 열 때 한 번 모은다.
class MyPostsViewModel extends ViewModel {
  MyPostsViewModel(
    PrayerRepository prayerRepo,
    ContentRepository contents,
    ReflectionRepository reflections,
    String churchId,
    String uid, {
    bool includePrivate = false,
    List<String>? affiliationIds,
  }) : _prayerRepo = prayerRepo,
       _churchId = churchId {
    // 종류를 빠르게 오가도 구독이 반복해서 붙고 떨어지지 않도록, 한 번만 구독해 값을 들고 있는다.
    _subs.add(
      prayerRepo
          .myPrayers(churchId)
          .listen(
            (v) {
              prayerList = v;
              notifyListeners();
            },
            onError: (Object e) {
              prayerError = e;
              notifyListeners();
            },
          ),
    );
    _subs.add(
      contents
          .latest(
            churchId,
            includePrivate: includePrivate,
            affiliationIds: affiliationIds,
          )
          .listen(
            (list) {
              devotionList = [
                for (final c in list)
                  if (c.authorId == uid) c,
              ];
              notifyListeners();
            },
            onError: (Object e) {
              devotionError = e;
              notifyListeners();
            },
          ),
    );
    // 댓글은 처음 열 때 한 번 모은다.
    reflections
        .mineAcrossChurch(churchId)
        .then(
          (v) {
            commentList = v;
            notifyListeners();
          },
          onError: (Object e) {
            commentError = e;
            notifyListeners();
          },
        );
  }

  final PrayerRepository _prayerRepo;
  final String _churchId;
  final List<StreamSubscription<Object?>> _subs = [];

  List<Prayer>? prayerList;
  Object? prayerError;
  List<ChurchContent>? devotionList;
  Object? devotionError;
  List<MyComment>? commentList;
  Object? commentError;

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  MyPostFilter _filter = MyPostFilter.prayer;
  MyPostSort _sort = MyPostSort.latest;

  MyPostFilter get filter => _filter;
  MyPostSort get sort => _sort;

  /// 고른 종류에서 쓸 수 있는 정렬: 댓글에는 조회수 · 좋아요가 없어 최신순 · 오래된순만 있다.
  List<MyPostSort> get sortOptions => _filter == MyPostFilter.comment
      ? const [MyPostSort.latest, MyPostSort.oldest]
      : MyPostSort.values;

  void setFilter(MyPostFilter value) {
    if (_filter == value) return;
    _filter = value;
    if (!sortOptions.contains(_sort)) _sort = MyPostSort.latest;
    notifyListeners();
  }

  void setSort(MyPostSort value) {
    if (_sort == value) return;
    _sort = value;
    notifyListeners();
  }

  int _cmp(DateTime? a, DateTime? b) {
    final x = a ?? DateTime(1970);
    final y = b ?? DateTime(1970);
    return _sort == MyPostSort.oldest ? x.compareTo(y) : y.compareTo(x);
  }

  /// 글별 응원(이모티콘) 합. 중보기도를 좋아요순으로 정렬할 때 처음 한 번 읽어 둔다.
  final Map<String, int> _likes = {};
  bool _loadingLikes = false;

  Future<void> ensureLikes(List<Prayer> list) async {
    if (_loadingLikes) return;
    final missing = [
      for (final p in list)
        if (!_likes.containsKey(p.id)) p,
    ];
    if (missing.isEmpty) return;
    _loadingLikes = true;
    final totals = await Future.wait([
      for (final p in missing)
        _prayerRepo
            .reactions(_churchId, p.id)
            .first
            .then((r) => r.total, onError: (_) => 0),
    ]);
    _loadingLikes = false;
    for (var i = 0; i < missing.length; i++) {
      _likes[missing[i].id] = totals[i];
    }
    notifyListeners();
  }

  List<Prayer> sortedPrayers(List<Prayer> list) => [...list]
    ..sort(
      (a, b) => switch (_sort) {
        MyPostSort.views => b.views.compareTo(a.views),
        MyPostSort.likes => (_likes[b.id] ?? 0).compareTo(_likes[a.id] ?? 0),
        _ => _cmp(a.createdAt, b.createdAt),
      },
    );

  List<ChurchContent> sortedDevotions(List<ChurchContent> list) =>
      [...list]..sort(
        (a, b) => switch (_sort) {
          MyPostSort.views => b.views.compareTo(a.views),
          MyPostSort.likes => b.likes.compareTo(a.likes),
          _ => _cmp(a.date, b.date),
        },
      );

  List<MyComment> sortedComments(List<MyComment> list) =>
      [...list]..sort((a, b) => _cmp(a.date, b.date));
}
