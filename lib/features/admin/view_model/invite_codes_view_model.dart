import '../../../core/mvvm/view_model.dart';
import '../../../data/models/invite_code.dart';
import '../../../data/models/member.dart';
import '../../church/data/church_repository.dart';

/// 이 교회의 초대 코드 목록 / 새로 발급(역할·일회용 지정) / 폐기.
class InviteCodesViewModel extends ViewModel {
  InviteCodesViewModel(this._churches, this.me)
    : codes = _churches.inviteCodes(me.churchId);

  final ChurchRepository _churches;
  final Member me;
  final Stream<List<InviteCode>> codes;

  /// 교역자 역할의 코드는 교회 운영자만 만들 수 있다.
  bool get canInviteStaff => me.role == Role.admin;

  Future<bool> create({Role role = Role.member, bool singleUse = false}) => run(
    () => _churches.createInviteCode(
      me.churchId,
      me.churchName,
      role: role,
      singleUse: singleUse,
    ),
  );

  Future<bool> revoke(String code) =>
      run(() => _churches.revokeInviteCode(code));
}
