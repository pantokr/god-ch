import '../../../core/mvvm/view_model.dart';
import '../../../data/models/meeting.dart';
import '../data/meeting_repository.dart';
import '../view/meeting_form.dart';

/// 모임 상세: 모임 한 건(실시간), 참여 신청 · 취소, 좋아요, 수정 · 삭제. 열 때 조회수를 하나 올린다.
class MeetingDetailViewModel extends ViewModel {
  MeetingDetailViewModel(this._repo, this.churchId, this.id)
    : meeting = _repo.one(churchId, id) {
    // 조회수 기록이 실패해도 글을 보는 데는 영향이 없다.
    _repo.addView(churchId, id).catchError((Object _) {});
  }

  final MeetingRepository _repo;
  final String churchId;
  final String id;
  final Stream<Meeting?> meeting;

  Future<bool> setJoined(bool joined) =>
      run(() => _repo.setJoined(churchId, id, joined: joined));

  Future<bool> setLike(bool liked) =>
      run(() => _repo.setLike(churchId, id, liked: liked), blocking: false);

  Future<bool> update(Meeting m, MeetingFormResult v) => run(
    () => _repo.update(
      churchId,
      m,
      title: v.title,
      description: v.description,
      place: v.place,
      date: v.date,
      capacity: v.capacity,
    ),
  );

  Future<bool> delete() => run(() => _repo.delete(churchId, id));
}
