import '../../../core/mvvm/view_model.dart';
import '../../../data/models/prayer.dart';

/// 기도제목 목록 화면(교회 피드, 내 기도제목, 관리 목록)이 공유하는 ViewModel.
/// 스트림을 한 번만 만들어 두어, 화면이 다시 그려져도 재구독하지 않는다.
class PrayerListViewModel extends ViewModel {
  PrayerListViewModel(this.prayers);

  final Stream<List<Prayer>> prayers;
}
