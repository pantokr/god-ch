import '../../../core/mvvm/view_model.dart';
import '../../../data/models/church.dart';
import '../data/church_registry_repository.dart';

/// 주소의 교회 ID로 교회 한 곳을 불러온다 (앱 운영자의 교회 상세 관리).
class ChurchLookupViewModel extends ViewModel {
  ChurchLookupViewModel(ChurchRegistryRepository registry, String churchId)
    : church = registry.church(churchId);

  final Stream<Church?> church;
}
