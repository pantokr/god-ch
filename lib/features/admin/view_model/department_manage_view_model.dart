import '../../../core/app_exception.dart';
import '../../../core/mvvm/view_model.dart';
import '../../../data/models/church_features.dart';
import '../../../data/models/department.dart';
import '../../../data/models/page_layout.dart';
import '../../../data/models/member.dart';
import '../../church/data/department_repository.dart';
import '../../members/data/member_repository.dart';

/// 부서 관리: 부서 목록(만들기 · 이름 변경)과 부서별 인원(추가 · 빼기).
/// 목록 화면과 부서 상세 화면이 함께 쓴다. 스트림은 한 번만 만든다.
class DepartmentManageViewModel extends ViewModel {
  DepartmentManageViewModel(this._departments, this._members, this.churchId)
    : departments = _departments.departments(churchId),
      members = _members.members(churchId),
      features = _departments.features(churchId) {
    // 교회 운영자가 모든 부서에 속해 있게 맞춘다 (예전 데이터 포함, 이미 맞으면 쓰지 않는다).
    _members.syncAdminDepartments(churchId).catchError((_) {});
  }

  final DepartmentRepository _departments;
  final MemberRepository _members;
  final String churchId;
  final Stream<List<Department>> departments;
  final Stream<List<Member>> members;

  /// 부서별로 기도 · 말씀 탭을 쓸 수 있는지.
  final Stream<ChurchFeatures> features;

  /// 이 부서에 속한 인원. 이름 순.
  List<Member> inDepartment(List<Member> all, String departmentId) =>
      all.where((m) => m.departmentIds.contains(departmentId)).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  /// 이 부서에 넣을 수 있는 인원: 승인된 교인 중 아직 속하지 않은 사람.
  List<Member> candidates(List<Member> all, String departmentId) =>
      all
          .where((m) => m.isApproved && !m.departmentIds.contains(departmentId))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  /// [department] 부서의 [group](기도 · 말씀) 탭을 켜거나 끈다.
  Future<bool> setFeature(
    ChurchFeatures current,
    List<Department> all,
    Department department,
    PageGroup group,
    bool on,
  ) => run(
    () => _departments.setFeatures(
      churchId,
      current.toggled(group, department.id, on, [for (final d in all) d.id]),
    ),
  );

  Future<bool> create(String name) =>
      run(() => _departments.create(churchId, name));

  Future<bool> rename(String id, String name) =>
      run(() => _departments.rename(churchId, id, name));

  Future<bool> add(String departmentId, Iterable<Member> people) =>
      run(() async {
        for (final m in people) {
          await _members.addToDepartment(churchId, m.id, departmentId);
        }
      });

  /// 교회 운영자는 모든 부서에 자동으로 속하므로 부서에서 뺄 수 없다.
  Future<bool> remove(String departmentId, Member m) => run(() {
    if (m.role == Role.admin) {
      throw const AppException('교회 운영자는 모든 부서에 자동으로 속해요.');
    }
    return _members.removeFromDepartment(churchId, m.id, departmentId);
  });
}
