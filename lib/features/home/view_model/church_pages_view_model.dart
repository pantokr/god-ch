import '../../../core/mvvm/view_model.dart';
import '../../../data/models/page_layout.dart';
import '../data/page_layout_repository.dart';

/// 교회의 페이지 구성(메뉴와 각 페이지의 구조). 틀이 한 번만 구독한다.
class ChurchPagesViewModel extends ViewModel {
  ChurchPagesViewModel(PageLayoutRepository repository, String churchId)
    : pages = repository.pages(churchId);

  final Stream<List<PageConfig>> pages;
}

/// 페이지 구성 편집: 고친 구성을 한꺼번에 저장한다.
class PageLayoutEditorViewModel extends ViewModel {
  PageLayoutEditorViewModel(this._repository, this._churchId);

  final PageLayoutRepository _repository;
  final String _churchId;

  Future<bool> save(List<PageConfig> pages, List<String> removedIds) =>
      run(() => _repository.save(_churchId, pages, removedIds: removedIds));
}
