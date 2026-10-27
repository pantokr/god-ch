import '../../../core/mvvm/view_model.dart';
import '../../../data/models/department.dart';
import '../../../data/models/member.dart';
import '../../church/data/church_repository.dart';
import '../../church/data/department_repository.dart';

/// 내 정보에 보여줄 소속: 내가 속한 교회들과, 교회마다 내가 속한 부서들. 스트림은 한 번만 만든다.
class MyAffiliationsViewModel extends ViewModel {
  MyAffiliationsViewModel(ChurchRepository churches, this._departments)
    : memberships = churches.myMemberships();

  final DepartmentRepository _departments;

  /// 내가 속하거나 요청한 모든 교회에서의 내 정보. 화면은 이 중 승인된 교회만 보여준다.
  final Stream<List<Member>> memberships;

  final _byChurch = <String, Stream<List<Department>>>{};

  /// [churchId] 교회의 부서들 (이름을 보여주려고). 교회마다 한 번만 구독한다.
  Stream<List<Department>> departmentsOf(String churchId) =>
      _byChurch.putIfAbsent(churchId, () => _departments.departments(churchId));
}
