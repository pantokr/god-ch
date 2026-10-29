import 'dart:async';

import '../../../core/mvvm/view_model.dart';
import '../../../data/models/member.dart';
import '../../../data/models/prayer.dart';
import '../../../data/models/prayer_settings.dart';
import '../data/prayer_repository.dart';

/// 기도제목 작성 / 수정. [existing]이 있으면 수정 모드.
class PrayerEditorViewModel extends ViewModel {
  PrayerEditorViewModel(this._prayers, this.me, {this.existing})
    : _visibility = existing?.visibility ?? PrayerVisibility.public {
    _settingsSub = _prayers.settings(me.churchId).listen((s) {
      _settings = s;
      // 처음 쓸 때, 아직 고르지 않았다면 교회가 정한 기본 공개 범위를 따른다.
      if (!isEditing && !_touched) _visibility = s.defaultVisibility;
      if (!s.allowPrivate) _visibility = PrayerVisibility.public;
      notifyListeners();
    });
  }

  final PrayerRepository _prayers;
  final Member me;
  final Prayer? existing;

  PrayerVisibility _visibility;
  bool _touched = false;
  PrayerSettings _settings = PrayerSettings.standard;
  late final StreamSubscription<PrayerSettings> _settingsSub;

  /// 교회가 정한 기도 요청 운영 설정.
  PrayerSettings get settings => _settings;

  /// 내가 이 교회에서 새 기도제목을 쓸 수 있는가.
  bool get canWrite =>
      isEditing || _settings.writers == PrayerWriters.member || me.isStaff;

  @override
  void dispose() {
    _settingsSub.cancel();
    super.dispose();
  }

  bool get isEditing => existing != null;

  PrayerVisibility get visibility => _visibility;

  void setVisibility(PrayerVisibility value) {
    _touched = true;
    _visibility = value;
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
