import '../../../core/mvvm/view_model.dart';
import '../../../data/models/meeting.dart';
import '../data/meeting_repository.dart';
import 'meetings_view_model.dart';

/// 내 활동의 일정을 나누어 보는 방식.
enum MyMeetingView {
  upcoming('참여 예정'),
  liked('관심 일정'),
  attended('완료');

  const MyMeetingView(this.label);

  final String label;
}

/// 내 활동의 "일정": 최근 모임을 참여 예정 · 관심 · 참여 일정으로 나누어 본다.
/// 참여는 내가 참여자이거나 모임장인 경우다. 스트림은 한 번만 만들고 나누기는 화면이 바로 한다.
class MyMeetingsViewModel extends ViewModel {
  MyMeetingsViewModel(this._repo, this._churchId, this._uid)
    : items = _repo.latest(_churchId);

  final MeetingRepository _repo;
  final String _churchId;
  final String _uid;
  final Stream<List<Meeting>> items;

  MyMeetingView _view = MyMeetingView.upcoming;
  MeetingSort _sort = MeetingSort.latest;

  MeetingSort get sort => _sort;

  void setSort(MeetingSort value) {
    if (_sort == value) return;
    _sort = value;
    notifyListeners();
  }

  MyMeetingView get view => _view;

  void setView(MyMeetingView value) {
    if (_view == value) return;
    _view = value;
    notifyListeners();
  }

  bool _isMine(Meeting m) => m.joinedBy(_uid) || m.leaderId == _uid;

  bool _inView(Meeting m) => switch (_view) {
    MyMeetingView.upcoming => _isMine(m) && !m.ended,
    MyMeetingView.liked => m.likedByUser(_uid),
    MyMeetingView.attended => _isMine(m) && m.ended,
  };

  /// 고른 방식과 검색어에 맞는 모임을 일정 탭과 같은 정렬 기준대로 돌려준다.
  List<Meeting> apply(List<Meeting> all) => MeetingsViewModel.sorted([
    for (final m in all)
      if (_inView(m)) m,
  ], _sort);

  /// 목록의 하트를 누르거나 취소한다 (일정 탭과 같다).
  Future<bool> setLike(String id, {required bool liked}) =>
      run(() => _repo.setLike(_churchId, id, liked: liked), blocking: false);
}
