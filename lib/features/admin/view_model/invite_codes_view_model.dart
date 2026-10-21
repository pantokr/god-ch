import '../../../core/mvvm/view_model.dart';
import '../../../data/models/invite_code.dart';
import '../../../data/models/member.dart';
import '../../church/data/church_repository.dart';

/// 이 교회의 초대 코드 목록 / 새로 발급 / 폐기.
class InviteCodesViewModel extends ViewModel {
  InviteCodesViewModel(this._churches, this._me)
    : codes = _churches.inviteCodes(_me.churchId);

  final ChurchRepository _churches;
  final Member _me;
  final Stream<List<InviteCode>> codes;

  Future<bool> create() =>
      run(() => _churches.createInviteCode(_me.churchId, _me.churchName));

  Future<bool> revoke(String code) =>
      run(() => _churches.revokeInviteCode(code));
}
