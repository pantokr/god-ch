import '../../../core/mvvm/view_model.dart';
import '../../../data/models/meeting.dart';
import '../data/meeting_repository.dart';

/// 내 활동의 일정을 나누어 보는 방식.
enum MyMeetingView {
  upcoming('참여 예정'),
  liked('좋아요한 일정'),
  attended('참여한 일정');

  const MyMeetingView(this.label);

  final String label;
}

/// 내 활동의 "일정": 최근 모임을 참여 예정 · 좋아요한 · 참여한 일정으로 나누어 본다.
/// 참여는 내가 참여자이거나 모임장인 경우다. 스트림은 한 번만 만들고 나누기는 화면이 바로 한다.
class MyMeetingsViewModel extends ViewModel {
  MyMeetingsViewModel(this._repo, this._churchId, this._uid)
    : items = _repo.latest(_churchId);

  final MeetingRepository _repo;
  final String _churchId;
  final String _uid;
  final Stream<List<Meeting>> items;

  MyMeetingView _view = MyMeetingView.upcoming;

  MyMeetingView get view => _view;

  void setView(MyMeetingView value) {
    if (_view == value) return;
    _view = value;
    notifyListeners();
  }

  bool _isMine(Meeting m) => m.joinedBy(_uid) || m.leaderId == _uid;

  /// 고른 방식에 맞는 모임. 참여 예정은 가까운 날짜순, 참여한 일정은 최근 날짜순이다.
  List<Meeting> apply(List<Meeting> all) {
    switch (_view) {
      case MyMeetingView.upcoming:
        return [
          for (final m in all)
            if (_isMine(m) && !m.ended) m,
        ]..sort((a, b) => a.date.compareTo(b.date));
      case MyMeetingView.liked:
        return [
          for (final m in all)
            if (m.likedByUser(_uid)) m,
        ];
      case MyMeetingView.attended:
        return [
          for (final m in all)
            if (_isMine(m) && m.ended) m,
        ]..sort((a, b) => b.date.compareTo(a.date));
    }
  }

  /// 목록의 하트를 누르거나 취소한다 (일정 탭과 같다).
  Future<bool> setLike(String id, {required bool liked}) =>
      run(() => _repo.setLike(_churchId, id, liked: liked), blocking: false);
}
