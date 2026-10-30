import '../../../core/mvvm/view_model.dart';
import '../../../data/models/devotion_reflection.dart';
import '../../../data/models/member.dart';
import '../data/reflection_repository.dart';

/// 말씀묵상 한 편의 댓글들과, 댓글 달기 · 지우기. 한 사람이 여러 댓글을 달 수 있다.
/// 스트림은 한 번만 만들어 다시 그려도 재구독하지 않는다.
class DevotionReflectionsViewModel extends ViewModel {
  DevotionReflectionsViewModel(
    this._repo,
    this.me,
    this.devotionId, {
    bool publicList = true,
  }) : reflections = publicList || me.isStaff
           ? _repo.latest(me.churchId, devotionId)
           : _repo.onlyMine(me.churchId, devotionId);

  final ReflectionRepository _repo;
  final Member me;
  final String devotionId;
  final Stream<List<DevotionReflection>> reflections;

  Future<bool> add(String text) => run(
    () => _repo.add(me.churchId, devotionId, authorName: me.name, text: text),
    blocking: false,
  );

  Future<bool> delete(String commentId) => run(
    () => _repo.delete(me.churchId, devotionId, commentId),
    blocking: false,
  );
}
