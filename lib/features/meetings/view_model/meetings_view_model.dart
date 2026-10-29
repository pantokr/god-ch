import '../../../core/mvvm/view_model.dart';
import '../../../data/models/meeting.dart';
import '../data/meeting_repository.dart';
import '../view/meeting_form.dart';

/// 모임 목록과 새 모임 만들기. 스트림은 한 번만 만든다.
class MeetingsViewModel extends ViewModel {
  MeetingsViewModel(this._repo, this.churchId, this.leaderName)
    : items = _repo.latest(churchId);

  final MeetingRepository _repo;
  final String churchId;
  final String leaderName;
  final Stream<List<Meeting>> items;

  Future<bool> create(MeetingFormResult v) => run(
    () => _repo.create(
      churchId,
      leaderName: leaderName,
      title: v.title,
      description: v.description,
      place: v.place,
      date: v.date,
      capacity: v.capacity,
    ),
  );
}
