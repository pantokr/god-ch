import 'dart:async';

import '../../../core/mvvm/view_model.dart';
import '../../../data/models/member.dart';
import '../../../data/models/permission.dart';
import '../../../data/models/prayer.dart';
import '../../../data/models/prayer_settings.dart';
import '../data/prayer_repository.dart';

/// 기도제목 작성 / 수정. [existing]이 있으면 수정 모드.
class PrayerEditorViewModel extends ViewModel {
  PrayerEditorViewModel(
    this._prayers,
    this.me, {
    this.existing,
    String? defaultAffiliationId,
  }) : _visibility = existing?.visibility ?? PrayerVisibility.public,
       _affiliationId = existing?.affiliationId ?? defaultAffiliationId {
    _settingsSub = _prayers.settings(me.churchId).listen((s) {
      _settings = s;
      if (!s.allowPrivate) _visibility = PrayerVisibility.public;
      notifyListeners();
    });
  }

  final PrayerRepository _prayers;
  final Member me;
  final Prayer? existing;

  PrayerVisibility _visibility;
  PrayerSettings _settings = PrayerSettings.standard;
  late final StreamSubscription<PrayerSettings> _settingsSub;

  /// 교회가 정한 기도 요청 운영 설정.
  PrayerSettings get settings => _settings;

  /// 내가 이 교회에서 새 기도제목을 쓸 수 있는가.
  bool get canWrite => isEditing || me.can(Permission.prayerWrite);

  @override
  void dispose() {
    _settingsSub.cancel();
    super.dispose();
  }

  String? _affiliationId;

  bool get isEditing => existing != null;

  PrayerVisibility get visibility => _visibility;

  /// 게시 범위: null이면 교회 전체, 값이 있으면 그 소속 전용.
  String? get affiliationId => _affiliationId;

  void setAffiliation(String? affiliationId) {
    _affiliationId = affiliationId;
    notifyListeners();
  }

  void setVisibility(PrayerVisibility value) {
    _visibility = value;
    notifyListeners();
  }

  /// 저장에 성공하면 true.
  Future<bool> save({required String content}) => run(() {
    final current = existing;
    if (current == null) {
      return _prayers.create(
        me.churchId,
        authorName: me.name,
        content: content,
        visibility: _visibility,
        affiliationId: _affiliationId,
      );
    }
    return _prayers.update(
      me.churchId,
      current.id,
      content: content,
      visibility: _visibility,
    );
  });
}
