import '../../../core/mvvm/view_model.dart';
import '../../../data/models/page_layout.dart';
import '../../../data/models/prayer_settings.dart';
import '../../prayers/data/prayer_repository.dart';
import '../data/page_layout_repository.dart';

/// 교회의 페이지 구성(메뉴와 각 페이지의 구조). 틀이 한 번만 구독한다.
class ChurchPagesViewModel extends ViewModel {
  ChurchPagesViewModel(PageLayoutRepository repository, String churchId)
    : pages = repository.pages(churchId);

  final Stream<List<PageConfig>> pages;
}

/// 페이지 구성 편집: 고친 구성을 한꺼번에 저장한다.
class PageLayoutEditorViewModel extends ViewModel {
  PageLayoutEditorViewModel(this._repository, this._churchId, [this._prayers]);

  final PageLayoutRepository _repository;
  final String _churchId;
  final PrayerRepository? _prayers;

  Future<bool> save(List<PageConfig> pages, List<String> removedIds) =>
      run(() => _repository.save(_churchId, pages, removedIds: removedIds));

  /// 기도 요청 운영 설정을 불러온다. 정한 적 없으면 표준 설정.
  Future<PrayerSettings> loadPrayerSettings() async => _prayers == null
      ? PrayerSettings.standard
      : _prayers.loadSettings(_churchId);

  /// 페이지 구성과, 바뀐 기도 요청 운영 설정([prayer])을 함께 저장한다.
  Future<bool> saveAll(List<PageConfig> pages, PrayerSettings? prayer) =>
      run(() async {
        await _repository.save(_churchId, pages);
        if (prayer != null) await _prayers?.saveSettings(_churchId, prayer);
      });
}
