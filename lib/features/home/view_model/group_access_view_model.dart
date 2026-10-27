import '../../../core/mvvm/view_model.dart';
import '../../../data/models/church_features.dart';
import '../../../data/models/department.dart';
import '../../church/data/department_repository.dart';

/// 기도 · 말씀 탭의 접근 판단에 쓰는 자료: 이 교회의 부서들과 부서별 기능 설정. 스트림은 한 번만 만든다.
class GroupAccessViewModel extends ViewModel {
  GroupAccessViewModel(DepartmentRepository departments, String churchId)
    : departments = departments.departments(churchId),
      features = departments.features(churchId);

  final Stream<List<Department>> departments;
  final Stream<ChurchFeatures> features;
}
