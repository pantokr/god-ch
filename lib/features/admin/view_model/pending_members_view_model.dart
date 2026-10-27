import '../../../core/mvvm/view_model.dart';
import '../../members/data/member_repository.dart';

/// 입장 요청(승인 대기) 수. 왼쪽 메뉴의 인원 관리와 알림 버튼이 함께 쓴다. 스트림은 한 번만 만든다.
class PendingMembersViewModel extends ViewModel {
  PendingMembersViewModel(MemberRepository members, String churchId)
    : count = members.pendingCount(churchId);

  final Stream<int> count;
}
