import '../../../core/mvvm/view_model.dart';
import '../../../data/models/department.dart';
import '../../../data/models/invite_code.dart';
import '../../../data/models/member.dart';
import '../../church/data/church_repository.dart';
import '../../church/data/department_repository.dart';

/// 이 교회의 초대 코드 목록 / 새로 발급(역할·부서·일회용 지정) / 폐기.
class InviteCodesViewModel extends ViewModel {
  InviteCodesViewModel(
    this._churches,
    DepartmentRepository departments,
    this.me,
  ) : codes = _churches.inviteCodes(me.churchId),
      departments = departments.departments(me.churchId);

  final ChurchRepository _churches;
  final Member me;
  final Stream<List<InviteCode>> codes;
  final Stream<List<Department>> departments;

  /// 교역자 역할의 코드는 교회 운영자만 만들 수 있다.
  bool get canInviteStaff => me.role == Role.admin;

  Future<bool> create({
    Role role = Role.member,
    List<String> departmentIds = const [],
    bool singleUse = false,
  }) => run(
    () => _churches.createInviteCode(
      me.churchId,
      me.churchName,
      role: role,
      departmentIds: departmentIds,
      singleUse: singleUse,
    ),
  );

  Future<bool> revoke(String code) =>
      run(() => _churches.revokeInviteCode(code));
}
