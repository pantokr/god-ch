import '../../../core/mvvm/view_model.dart';
import '../../../data/models/meeting.dart';
import '../data/meeting_repository.dart';
import 'meetings_view_model.dart' show MeetingSort, MeetingsViewModel;

/// 전체 일정 조회의 범위: 모든 일정 / 내가 만든 일정.
enum MeetingOwner {
  all('전체 일정'),
  mine('내가 만든 일정');

  const MeetingOwner(this.label);

  final String label;
}

/// 전체 일정 조회: 모든 일정을 범위(전체 · 내가 만든)로 거르고, 제목과 작성자(모임장)로 검색한다.
/// 스트림은 한 번만 만든다.
class AllMeetingsViewModel extends ViewModel {
  AllMeetingsViewModel(this._repo, this._churchId, this._uid)
    : items = _repo.latest(_churchId);

  final MeetingRepository _repo;
  final String _churchId;
  final String _uid;
  final Stream<List<Meeting>> items;

  MeetingOwner _owner = MeetingOwner.all;
  MeetingSort _sort = MeetingSort.latest;
  String _query = '';

  MeetingOwner get owner => _owner;
  MeetingSort get sort => _sort;
  String get query => _query;

  void setOwner(MeetingOwner v) {
    if (_owner == v) return;
    _owner = v;
    notifyListeners();
  }

  void setSort(MeetingSort v) {
    if (_sort == v) return;
    _sort = v;
    notifyListeners();
  }

  void setQuery(String v) {
    _query = v.trim().toLowerCase();
    notifyListeners();
  }

  /// 제목 또는 작성자(모임장 이름)에 검색어가 들어 있는가.
  bool _matchesQuery(Meeting m) =>
      _query.isEmpty ||
      m.title.toLowerCase().contains(_query) ||
      m.leaderName.toLowerCase().contains(_query);

  /// 고른 범위 · 검색어에 맞는 일정을 고른 정렬 기준대로.
  List<Meeting> apply(List<Meeting> all) => MeetingsViewModel.sorted([
    for (final m in all)
      if ((_owner == MeetingOwner.all || m.leaderId == _uid) &&
          _matchesQuery(m))
        m,
  ], _sort);

  /// 목록에서 하트를 누르거나 취소한다 (일정 탭과 같다).
  Future<bool> setLike(String id, {required bool liked}) =>
      run(() => _repo.setLike(_churchId, id, liked: liked), blocking: false);
}
