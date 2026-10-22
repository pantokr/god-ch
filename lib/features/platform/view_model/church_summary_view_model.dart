import '../../../core/mvvm/view_model.dart';
import '../../../data/models/member.dart';
import '../../members/data/member_repository.dart';

/// 교회 정보 탭의 교인 현황(승인된 교인 수, 승인 대기 수).
class ChurchSummaryViewModel extends ViewModel {
  ChurchSummaryViewModel(MemberRepository members, String churchId)
    : members = members.members(churchId);

  final Stream<List<Member>> members;
}
