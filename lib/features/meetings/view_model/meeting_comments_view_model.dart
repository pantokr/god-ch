import '../../../core/mvvm/view_model.dart';
import '../../../data/models/meeting_comment.dart';
import '../../../data/models/member.dart';
import '../data/meeting_repository.dart';

/// 일정 한 건의 댓글 목록과, 댓글 쓰기 · 지우기. 스트림은 한 번만 만든다.
class MeetingCommentsViewModel extends ViewModel {
  MeetingCommentsViewModel(this._repo, this.me, this.meetingId)
    : comments = _repo.comments(me.churchId, meetingId);

  final MeetingRepository _repo;
  final Member me;
  final String meetingId;
  final Stream<List<MeetingComment>> comments;

  Future<bool> add(String text) => run(
    () => _repo.addComment(
      me.churchId,
      meetingId,
      authorName: me.name,
      text: text,
    ),
    blocking: false,
  );

  Future<bool> delete(MeetingComment c) => run(
    () => _repo.deleteComment(me.churchId, meetingId, c.id),
    blocking: false,
  );
}
