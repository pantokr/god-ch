import '../../../core/mvvm/view_model.dart';
import '../../../data/models/department.dart';
import '../../../data/models/member.dart';
import '../../church/data/department_repository.dart';
import '../../members/data/member_repository.dart';

/// 부서 관리: 부서 목록(만들기 · 이름 변경)과 부서별 인원(추가 · 빼기).
/// 목록 화면과 부서 상세 화면이 함께 쓴다. 스트림은 한 번만 만든다.
class DepartmentManageViewModel extends ViewModel {
  DepartmentManageViewModel(this._departments, this._members, this.churchId)
    : departments = _departments.departments(churchId),
      members = _members.members(churchId);

  final DepartmentRepository _departments;
  final MemberRepository _members;
  final String churchId;
  final Stream<List<Department>> departments;
  final Stream<List<Member>> members;

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

  Future<bool> remove(String departmentId, Member m) =>
      run(() => _members.removeFromDepartment(churchId, m.id, departmentId));
}
