import '../../../core/mvvm/view_model.dart';
import '../../../data/models/devotion_reflection.dart';
import '../../../data/models/member.dart';
import '../data/reflection_repository.dart';

/// 말씀묵상 한 편에 남겨진 교인들의 글과, 내 글을 쓰고 지우는 동작.
/// 스트림은 한 번만 만들어 다시 그려도 재구독하지 않는다.
class DevotionReflectionsViewModel extends ViewModel {
  DevotionReflectionsViewModel(this._repo, this.me, this.devotionId)
    : reflections = _repo.latest(me.churchId, devotionId);

  final ReflectionRepository _repo;
  final Member me;
  final String devotionId;
  final Stream<List<DevotionReflection>> reflections;

  Future<bool> save(String text) => run(
    () => _repo.saveMine(
      me.churchId,
      devotionId,
      authorName: me.name,
      text: text,
    ),
  );

  Future<bool> delete(String authorId) =>
      run(() => _repo.delete(me.churchId, devotionId, authorId));
}
