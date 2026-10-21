import '../../../core/mvvm/view_model.dart';
import '../../../data/models/member.dart';
import '../../../data/models/prayer.dart';
import '../data/prayer_repository.dart';

/// 기도제목 작성 / 수정. [existing]이 있으면 수정 모드.
class PrayerEditorViewModel extends ViewModel {
  PrayerEditorViewModel(
    this._prayers,
    this.me, {
    this.existing,
    String? defaultDepartmentId,
  }) : _visibility = existing?.visibility ?? PrayerVisibility.public,
       _departmentId = existing?.departmentId ?? defaultDepartmentId;

  final PrayerRepository _prayers;
  final Member me;
  final Prayer? existing;

  PrayerVisibility _visibility;
  String? _departmentId;

  bool get isEditing => existing != null;

  PrayerVisibility get visibility => _visibility;

  /// 게시 범위: null이면 교회 전체, 값이 있으면 그 부서 전용.
  String? get departmentId => _departmentId;

  void setVisibility(PrayerVisibility value) {
    _visibility = value;
    notifyListeners();
  }

  void setDepartment(String? departmentId) {
    _departmentId = departmentId;
    notifyListeners();
  }

  /// 저장에 성공하면 true.
  Future<bool> save({required String title, required String content}) =>
      run(() {
        final current = existing;
        if (current == null) {
          return _prayers.create(
            me.churchId,
            title: title,
            content: content,
            visibility: _visibility,
            departmentId: _departmentId,
          );
        }
        return _prayers.update(
          me.churchId,
          current.id,
          title: title,
          content: content,
          visibility: _visibility,
        );
      });
}
