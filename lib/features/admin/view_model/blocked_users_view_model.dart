import '../../../core/mvvm/view_model.dart';
import '../../../data/models/blocked_user.dart';
import '../../../data/models/member.dart';
import '../../members/data/member_repository.dart';

/// 교회 차단 목록: 목록 보기 / 아이디로 직접 차단 / 차단 해제.
/// 차단하고 해제하는 것은 교회 운영자만 한다 (규칙이 강제한다).
class BlockedUsersViewModel extends ViewModel {
  BlockedUsersViewModel(this._members, this.me)
    : blocked = _members.blockedUsers(me.churchId);

  final MemberRepository _members;
  final Member me;
  final Stream<List<BlockedUser>> blocked;

  bool get canEdit => me.isAdmin;

  Future<bool> blockById(String loginId) =>
      run(() => _members.blockByLoginId(me.churchId, me.churchName, loginId));

  Future<bool> unblock(BlockedUser user) =>
      run(() => _members.unblock(me.churchId, user.uid));
}
