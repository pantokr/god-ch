import '../../../core/mvvm/view_model.dart';
import '../../../data/models/department.dart';
import '../data/department_repository.dart';

/// 한 교회의 부서 목록과 관리(만들기·이름 변경).
/// 내 교회 카드, 글쓰기, 관리 화면에서 함께 쓴다.
class DepartmentsViewModel extends ViewModel {
  DepartmentsViewModel(this._repository, this.churchId)
    : departments = _repository.departments(churchId);

  final DepartmentRepository _repository;
  final String churchId;
  final Stream<List<Department>> departments;

  Future<bool> create(String name) =>
      run(() => _repository.create(churchId, name));

  Future<bool> rename(String id, String name) =>
      run(() => _repository.rename(churchId, id, name));
}
