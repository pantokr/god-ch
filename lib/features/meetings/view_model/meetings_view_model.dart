import 'dart:typed_data';

import '../../../core/mvvm/view_model.dart';
import '../../../data/models/meeting.dart';
import '../data/meeting_repository.dart';
import '../view/meeting_form.dart';

/// 모임 목록 보기: 전체 / 신청할 수 있는 모임 / 마감된 모임.
enum MeetingFilter {
  all('전체'),
  open('신청 가능'),
  closed('마감');

  const MeetingFilter(this.label);

  final String label;
}

/// 모임 목록 정렬 기준.
enum MeetingSort {
  latest('최신순'),
  popular('인기순'),
  oldest('오래된순'),
  likes('좋아요순');

  const MeetingSort(this.label);

  final String label;
}

/// 모임 목록과 새 모임 만들기. 스트림은 한 번만 만든다.
class MeetingsViewModel extends ViewModel {
  MeetingsViewModel(this._repo, this.churchId, this.leaderName)
    : items = _repo.latest(churchId);

  final MeetingRepository _repo;
  final String churchId;
  final String leaderName;
  final Stream<List<Meeting>> items;

  MeetingSort _sort = MeetingSort.latest;
  MeetingFilter _filter = MeetingFilter.open;
  String _query = '';

  String get query => _query;

  void setQuery(String value) {
    _query = value.trim().toLowerCase();
    notifyListeners();
  }

  MeetingSort get sort => _sort;

  void setSort(MeetingSort value) {
    if (_sort == value) return;
    _sort = value;
    notifyListeners();
  }

  MeetingFilter get filter => _filter;

  void setFilter(MeetingFilter value) {
    if (_filter == value) return;
    _filter = value;
    notifyListeners();
  }

  /// 지금 보기에 맞는 모임인가.
  bool shows(Meeting m) => switch (_filter) {
    MeetingFilter.open => !(m.ended || m.isFull),
    MeetingFilter.all => true,
    MeetingFilter.closed => m.ended || m.isFull,
  };

  /// 검색어(제목 · 장소 · 모임장 · 소개), 보기(전체 · 신청 가능 · 마감), 정렬을 적용한 목록.
  List<Meeting> apply(List<Meeting> all) => sorted([
    for (final m in all)
      if (matches(m, _query) && shows(m)) m,
  ], _sort);

  /// 검색어([query], 소문자로 다듬은 것)에 맞는 모임인가 (제목 · 장소 · 모임장 · 소개). 내 활동도 같은 검색을 쓴다.
  static bool matches(Meeting m, String query) =>
      query.isEmpty ||
      m.title.toLowerCase().contains(query) ||
      m.place.toLowerCase().contains(query) ||
      m.leaderName.toLowerCase().contains(query) ||
      m.description.toLowerCase().contains(query);

  /// [sort] 기준으로 정렬한 목록 (받은 목록을 그대로 정렬한다).
  static List<Meeting> sorted(List<Meeting> list, MeetingSort sort) {
    DateTime made(Meeting m) => m.createdAt ?? m.date;
    switch (sort) {
      case MeetingSort.latest:
        list.sort((a, b) => made(b).compareTo(made(a)));
      case MeetingSort.popular:
        list.sort((a, b) => b.views.compareTo(a.views));
      case MeetingSort.oldest:
        list.sort((a, b) => made(a).compareTo(made(b)));
      case MeetingSort.likes:
        list.sort((a, b) => b.likes.compareTo(a.likes));
    }
    return list;
  }

  Future<bool> create(MeetingFormResult v) => run(
    () => _repo.create(
      churchId,
      leaderName: leaderName,
      title: v.title,
      description: v.description,
      place: v.place,
      date: v.date,
      capacity: v.capacity,
      imageUrl: v.imageUrl,
    ),
  );

  /// 목록에서 하트를 누르거나 취소한다. 목록이 실시간이라 화면에는 바로 반영된다.
  Future<bool> setLike(String id, {required bool liked}) =>
      run(() => _repo.setLike(churchId, id, liked: liked), blocking: false);

  /// 모임 썸네일 올리기. 실패하면 null.
  Future<String?> uploadImage(String fileName, Uint8List bytes) async {
    String? url;
    await run(() async => url = await _repo.uploadImage(churchId, bytes));
    return url;
  }
}
