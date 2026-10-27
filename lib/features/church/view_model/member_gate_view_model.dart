import '../../../core/mvvm/view_model.dart';
import '../../../data/models/member.dart';
import '../../platform/data/church_registry_repository.dart';
import '../data/church_repository.dart';
import '../data/church_request_repository.dart';

/// 주소의 교회 ID로 내가 그 교회의 승인된 교인인지 확인한다.
/// 링크로 바로 들어오거나 새로고침해도 소속을 다시 확인할 수 있다.
class MemberGateViewModel extends ViewModel {
  MemberGateViewModel(
    ChurchRepository churches,
    ChurchRequestRepository requests,
    ChurchRegistryRepository registry,
    String churchId,
  ) : member = _member(churches, requests, registry, churchId),
      closed = churches.isClosed(churchId) {
    // 다음에 로그인하면 이 교회로 바로 들어가도록 기억해 둔다.
    churches.rememberChurch(churchId);
  }

  /// 앱 개발자는 회원이 아니어도 교회를 열 수 있다: 교회 관리자와 같은 정보로 화면을 연다.
  /// 그 외에는 이 교회에서의 내 교인 정보.
  static Stream<Member?> _member(
    ChurchRepository churches,
    ChurchRequestRepository requests,
    ChurchRegistryRepository registry,
    String churchId,
  ) async* {
    final operator = await requests.isPlatformAdmin().first;
    if (!operator) {
      yield* churches.membership(churchId);
      return;
    }
    yield* registry
        .church(churchId)
        .map((c) => c == null ? null : registry.operatorViewOf(c));
  }

  /// 이 교회에서의 내 교인 정보. 신청하지 않았으면 null.
  final Stream<Member?> member;

  /// 폐쇄된 교회인가.
  final Stream<bool> closed;
}
