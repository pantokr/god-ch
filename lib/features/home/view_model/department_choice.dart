import '../../../core/mvvm/view_model.dart';

/// 기도 · 말씀 탭에서 지금 고른 부서. 위쪽 탭 줄의 부서 선택과 탭 내용이 함께 쓴다.
/// null이면 아직 고르지 않은 것이고, 선택지가 있으면 첫째 부서로 본다 ("전체"는 없다).
class DepartmentChoice extends ViewModel {
  String? _id;

  String? get id => _id;

  void select(String? id) {
    if (_id == id) return;
    _id = id;
    notifyListeners();
  }
}
