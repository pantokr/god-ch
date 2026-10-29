import '../../../core/mvvm/view_model.dart';
import '../../../data/models/church_content.dart';
import '../../home/data/content_repository.dart';

/// 성경(말씀 묵상) 화면: 최근 말씀 글 목록과, 교역자의 추가 · 수정 · 삭제. 스트림은 한 번만 만든다.
class DevotionsViewModel extends ViewModel {
  DevotionsViewModel(this._repo, this.churchId)
    : items = _repo.latest(churchId);

  final ContentRepository _repo;
  final String churchId;
  final Stream<List<ChurchContent>> items;

  Future<bool> save({
    String? id,
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

  Future<bool> delete(String id) => run(() => _repo.delete(churchId, id));
}
