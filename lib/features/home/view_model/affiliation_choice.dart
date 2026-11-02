import '../../../core/mvvm/view_model.dart';

/// 기도 · 말씀 탭에서 지금 고른 소속. 위쪽 탭 줄의 소속 선택과 탭 내용이 함께 쓴다.
/// null이면 아직 고르지 않은 것이고, 선택지가 있으면 첫째 소속으로 본다.
/// 교역자 이상은 [all]로 "전체"를 고를 수 있다.
class AffiliationChoice extends ViewModel {
  /// "전체"를 뜻하는 값 (소속 ID와 겹치지 않는다).
  static const all = '*all';

  String? _id;

  bool get isAll => _id == all;

  String? get id => _id;

  void select(String? id) {
    if (_id == id) return;
    _id = id;
    notifyListeners();
  }
}
