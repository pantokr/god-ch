import '../../../core/mvvm/view_model.dart';
import '../../../data/models/member.dart';
import '../data/church_repository.dart';

/// 주소의 교회 ID로 내가 그 교회의 승인된 교인인지 확인한다.
/// 링크로 바로 들어오거나 새로고침해도 소속을 다시 확인할 수 있다.
class MemberGateViewModel extends ViewModel {
  MemberGateViewModel(ChurchRepository churches, String churchId)
    : member = churches.membership(churchId),
      closed = churches.isClosed(churchId) {
    // 다음에 로그인하면 이 교회로 바로 들어가도록 기억해 둔다.
    churches.rememberChurch(churchId);
  }

  /// 이 교회에서의 내 교인 정보. 신청하지 않았으면 null.
  final Stream<Member?> member;

  /// 폐쇄된 교회인가.
  final Stream<bool> closed;
}
