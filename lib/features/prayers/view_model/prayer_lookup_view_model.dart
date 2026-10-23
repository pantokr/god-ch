import '../../../core/mvvm/view_model.dart';
import '../../../data/models/prayer.dart';
import '../data/prayer_repository.dart';

/// 주소의 ID로 기도제목 한 건을 불러온다 (수정 화면을 링크로 열었을 때).
class PrayerLookupViewModel extends ViewModel {
  PrayerLookupViewModel(
    PrayerRepository prayers,
    String churchId,
    String prayerId,
  ) : prayer = prayers.prayer(churchId, prayerId);

  final Stream<Prayer?> prayer;
}
