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
/// [baseVersion]은 화면을 연 때 본 마지막 저장 시각이다. 저장할 때마다 이 값을 갱신해서,
/// 내가 이어서 저장하는 것은 막지 않고 다른 관리자가 그사이 저장한 것만 막는다.
class PageLayoutEditorViewModel extends ViewModel {
  PageLayoutEditorViewModel(
    this._repository,
    this._churchId, [
    this._prayers,
    this._baseVersion,
  ]);

  final PageLayoutRepository _repository;
  final String _churchId;
  final PrayerRepository? _prayers;
  DateTime? _baseVersion;

  Future<bool> save(List<PageConfig> pages, List<String> removedIds) =>
      run(() async {
        _baseVersion = await _repository.save(
          _churchId,
          pages,
          removedIds: removedIds,
          expectedVersion: _baseVersion,
        );
      });

  /// 기도 요청 운영 설정을 불러온다. 정한 적 없으면 표준 설정.
  Future<PrayerSettings> loadPrayerSettings() async => _prayers == null
      ? PrayerSettings.standard
      : _prayers.loadSettings(_churchId);

  /// 페이지 구성과, 바뀐 기도 요청 운영 설정([prayer])을 함께 저장한다.
  Future<bool> saveAll(List<PageConfig> pages, PrayerSettings? prayer) =>
      run(() async {
        _baseVersion = await _repository.save(
          _churchId,
          pages,
          expectedVersion: _baseVersion,
        );
        if (prayer != null) await _prayers?.saveSettings(_churchId, prayer);
      });

  /// 이전 구성으로 되돌린다: 그 구성의 페이지들로 바꾸고, 지금 있는 나머지 페이지는 지운 것으로 표시한다.
  Future<bool> restore(PageRevision revision, List<PageConfig> current) {
    final keep = {for (final p in revision.pages) p.id};
    return save(revision.pages, [
      for (final p in current)
        if (!keep.contains(p.id)) p.id,
    ]);
  }
}
