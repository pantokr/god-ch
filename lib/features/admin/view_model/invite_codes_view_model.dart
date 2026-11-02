import '../../../core/mvvm/view_model.dart';
import '../../../data/models/affiliation.dart';
import '../../../data/models/invite_code.dart';
import '../../../data/models/member.dart';
import '../../church/data/affiliation_repository.dart';
import '../../church/data/church_repository.dart';

/// 이 교회의 초대 코드 목록 / 새로 발급(역할·소속·일회용 지정) / 폐기.
class InviteCodesViewModel extends ViewModel {
  InviteCodesViewModel(
    this._churches,
    AffiliationRepository affiliations,
    this.me,
  ) : _affiliationRepo = affiliations,
      codes = _churches.inviteCodes(me.churchId),
      affiliations = affiliations.affiliations(me.churchId);

  final AffiliationRepository _affiliationRepo;

  final ChurchRepository _churches;
  final Member me;
  final Stream<List<InviteCode>> codes;
  final Stream<List<Affiliation>> affiliations;

  /// 코드 만들기 창이 따로 구독하는 소속 목록. 목록 화면이 이미 구독한 [affiliations]는 두 번 구독할 수 없어서
  /// (창에는 소속이 "없음"만 보였다) 창마다 새 스트림을 만든다.
  Stream<List<Affiliation>> watchAffiliations() =>
      _affiliationRepo.affiliations(me.churchId);

  /// 교역자 역할의 코드는 교회 운영자만 만들 수 있다.
  bool get canInviteStaff => me.role == Role.admin;

  Future<bool> create({
    Role role = Role.member,
    List<String> affiliationIds = const [],
    bool singleUse = false,
  }) => run(
    () => _churches.createInviteCode(
      me.churchId,
      me.churchName,
      role: role,
      affiliationIds: affiliationIds,
      singleUse: singleUse,
    ),
  );

  Future<bool> revoke(String code) =>
      run(() => _churches.revokeInviteCode(code));
}
