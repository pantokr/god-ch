import '../../../core/mvvm/view_model.dart';

import 'dart:async';

import '../../../data/models/church_content.dart';
import '../../../data/models/devotion_settings.dart';
import '../../home/data/content_repository.dart';

/// 말씀 상세: 글 한 편(실시간), 좋아요, 수정 · 삭제. 글을 열 때 조회수를 하나 올린다.
class DevotionDetailViewModel extends ViewModel {
  DevotionDetailViewModel(this._repo, this.churchId, this.id)
    : content = _repo.one(churchId, id) {
    // 조회수 기록이 실패해도(권한 · 네트워크) 글을 보는 데는 영향이 없다.
    _repo.addView(churchId, id).catchError((Object _) {});
    _repo.markRead(churchId, id).catchError((Object _) {});
    _settingsSub = _repo.settings(churchId).listen((v) {
      settings = v;
      notifyListeners();
    }, onError: (_) {});
  }

  late final StreamSubscription<DevotionSettings> _settingsSub;

  /// 교회가 정한 말씀묵상 운영 설정.
  DevotionSettings settings = DevotionSettings.standard;

  @override
  void dispose() {
    _settingsSub.cancel();
    super.dispose();
  }

  final ContentRepository _repo;
  final String churchId;
  final String id;
  final Stream<ChurchContent?> content;

  Future<bool> setLike(bool liked) =>
      run(() => _repo.setLike(churchId, id, liked: liked), blocking: false);

  Future<bool> save({
    required String title,
    required String body,
    required String meditation,
    required DateTime date,
    String? affiliationId,
    bool isPrivate = false,
  }) => run(
    () => _repo.save(
      churchId,
      id: id,
      title: title,
      body: body,
      meditation: meditation,
      date: date,
      affiliationId: affiliationId,
      isPrivate: isPrivate,
    ),
  );

  Future<bool> delete() => run(() => _repo.delete(churchId, id));
}
