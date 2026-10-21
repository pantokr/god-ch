import '../../../core/mvvm/view_model.dart';
import '../../../data/models/member.dart';
import '../../members/data/member_repository.dart';

/// 교인 관리: 가입 승인, 비활성화, 역할 지정.
/// 교역자는 일반 교인의 승인 상태만, 관리자는 역할까지 바꿀 수 있다 (본인 계정은 제외).
class MemberAdminViewModel extends ViewModel {
  MemberAdminViewModel(this._members, this.me)
    : members = _members.members(me.churchId);

  final MemberRepository _members;
  final Member me;
  final Stream<List<Member>> members;

  bool canChangeStatus(Member m) =>
      m.id != me.id && (me.isAdmin || m.role == Role.member);

  bool canChangeRole(Member m) => m.id != me.id && me.isAdmin;

  /// 승인 대기 계정을 맨 위에 둔다.
  List<Member> sorted(List<Member> list) {
    int rank(Member m) => m.status == MemberStatus.pending ? 0 : 1;
    return [...list]..sort((a, b) => rank(a).compareTo(rank(b)));
  }

  Future<void> approve(Member m) =>
      run(() => _members.setStatus(me.churchId, m.id, MemberStatus.approved));

  Future<void> disable(Member m) =>
      run(() => _members.setStatus(me.churchId, m.id, MemberStatus.disabled));

  Future<void> setRole(Member m, Role role) =>
      run(() => _members.setRole(me.churchId, m.id, role));
}
