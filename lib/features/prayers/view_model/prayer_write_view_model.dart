import '../../../core/mvvm/view_model.dart';
import '../../../data/models/prayer_settings.dart';
import '../data/prayer_repository.dart';

/// 기도 요청 버튼: 교회가 정한 운영 설정(쓸 수 있는 사람)을 읽는다. 스트림은 한 번만 만든다.
class PrayerWriteViewModel extends ViewModel {
  PrayerWriteViewModel(PrayerRepository prayers, String churchId)
    : settings = prayers.settings(churchId);

  final Stream<PrayerSettings> settings;
}
