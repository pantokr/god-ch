import '../../../core/mvvm/view_model.dart';
import '../../../data/models/member.dart';
import '../../members/data/member_repository.dart';

/// 내가 소속할 부서를 고른다. 선택은 바로 저장되고, 실패하면 이전 상태로 되돌린다.
class MyDepartmentsViewModel extends ViewModel {
  MyDepartmentsViewModel(this._members, this._me)
    : _selected = {..._me.departmentIds};

  final MemberRepository _members;
  final Member _me;
  final Set<String> _selected;

  bool isSelected(String departmentId) => _selected.contains(departmentId);

  Future<void> toggle(String departmentId, bool on) async {
    final previous = {..._selected};
    if (on) {
      _selected.add(departmentId);
    } else {
      _selected.remove(departmentId);
    }
    final ok = await run(
      () => _members.setMyDepartments(_me.churchId, _selected.toList()),
    );
    if (!ok) {
      _selected
        ..clear()
        ..addAll(previous);
      notifyListeners();
    }
  }
}
