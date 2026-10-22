import '../../../core/mvvm/view_model.dart';
import '../../church/data/church_request_repository.dart';
import '../data/church_registry_repository.dart';

/// 앱 운영자 대시보드: 서비스 전체 현황을 숫자로 보여준다.
class PlatformDashboardViewModel extends ViewModel {
  PlatformDashboardViewModel(
    ChurchRegistryRepository registry,
    ChurchRequestRepository requests,
  ) : churchCount = registry.churches().map((l) => l.length),
      pendingRequestCount = requests.pendingRequests().map((l) => l.length),
      userCount = registry.users().map((l) => l.length);

  /// 등록된 교회 수.
  final Stream<int> churchCount;

  /// 승인을 기다리는 교회 생성 요청 수.
  final Stream<int> pendingRequestCount;

  /// 가입한 회원 수.
  final Stream<int> userCount;
}
