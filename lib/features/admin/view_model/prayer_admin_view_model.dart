import '../../../core/mvvm/view_model.dart';
import '../../../data/models/prayer.dart';
import '../../members/data/member_repository.dart';
import '../../prayers/data/prayer_repository.dart';

enum PrayerFilter { all, private, deleted }

/// 교역자 화면의 기도제목 관리 목록: 전체 / 교역자 전용 / 삭제됨.
class PrayerAdminViewModel extends ViewModel {
  PrayerAdminViewModel(
    PrayerRepository prayers,
    MemberRepository members,
    String churchId,
  ) : allPrayers = prayers.allPrayers(churchId),
      authorNames = members
          .members(churchId)
          .map((list) => {for (final m in list) m.id: m.name});

  final Stream<List<Prayer>> allPrayers;

  /// 작성자 uid → 이름. 교역자만 볼 수 있다.
  final Stream<Map<String, String>> authorNames;

  PrayerFilter _filter = PrayerFilter.all;

  PrayerFilter get filter => _filter;

  void setFilter(PrayerFilter value) {
    _filter = value;
    notifyListeners();
  }

  bool matches(Prayer p) => switch (_filter) {
    PrayerFilter.all => !p.deleted,
    PrayerFilter.private => !p.deleted && !p.isPublic,
    PrayerFilter.deleted => p.deleted,
  };
}
