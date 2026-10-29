import '../../../core/mvvm/view_model.dart';
import '../../../data/models/church_content.dart';
import '../../home/data/content_repository.dart';

/// 말씀 상세: 글 한 편(실시간), 좋아요, 수정 · 삭제. 글을 열 때 조회수를 하나 올린다.
class DevotionDetailViewModel extends ViewModel {
  DevotionDetailViewModel(this._repo, this.churchId, this.id)
    : content = _repo.one(churchId, id) {
    // 조회수 기록이 실패해도(권한 · 네트워크) 글을 보는 데는 영향이 없다.
    _repo.addView(churchId, id).catchError((Object _) {});
  }

  final ContentRepository _repo;
  final String churchId;
  final String id;
  final Stream<ChurchContent?> content;

  Future<bool> setLike(bool liked) =>
      run(() => _repo.setLike(churchId, id, liked: liked), blocking: false);

  Future<bool> save({
    required String title,
    required String body,
    required String meditation,
    required DateTime date,
  }) => run(
    () => _repo.save(
      churchId,
      id: id,
      title: title,
      body: body,
      meditation: meditation,
      date: date,
    ),
  );

  Future<bool> delete() => run(() => _repo.delete(churchId, id));
}
