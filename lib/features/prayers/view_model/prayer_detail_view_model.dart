import 'dart:async';

import '../../../core/mvvm/view_model.dart';
import '../../../data/models/member.dart';
import '../../../data/models/prayer.dart';
import '../../../data/models/prayer_settings.dart';
import '../../../data/models/text_entry.dart';
import '../data/prayer_repository.dart';

/// 기도제목 상세: 본문, 교역자 댓글·답변, 삭제·복구.
class PrayerDetailViewModel extends ViewModel {
  PrayerDetailViewModel(this._prayers, this.me, String prayerId)
    : prayer = _prayers.prayer(me.churchId, prayerId),
      comments = _prayers.comments(me.churchId, prayerId),
      responses = _prayers.responses(me.churchId, prayerId) {
    _settingsSub = _prayers.settings(me.churchId).listen((s) {
      _settings = s;
      notifyListeners();
    });
    // 주소로 바로 들어와도 글을 처음 불러온 때 한 번만 기록한다.
    _prayers.prayer(me.churchId, prayerId).first.then((p) {
      if (p != null) _recordOpened(p);
    }).ignore();
  }
  final PrayerRepository _prayers;
  final Member me;

  PrayerSettings _settings = PrayerSettings.standard;
  late final StreamSubscription<PrayerSettings> _settingsSub;

  /// 교회가 정한 기도 요청 운영 설정.
  PrayerSettings get settings => _settings;

  @override
  void dispose() {
    _settingsSub.cancel();
    super.dispose();
  }

  final Stream<Prayer?> prayer;

  /// 공개 글에 달린 교역자 댓글.
  final Stream<List<TextEntry>> comments;

  /// 비공개 글에 달린 교역자 답변.
  final Stream<List<TextEntry>> responses;

  bool isAuthor(Prayer p) => p.authorId == me.id;

  bool canEdit(Prayer p) => isAuthor(p) && !p.deleted;

  bool canDelete(Prayer p) =>
      !p.deleted &&
      ((isAuthor(p) && _settings.memberDelete) || (me.isStaff && !isAuthor(p)));

  bool canRestore(Prayer p) => p.deleted && me.isStaff;

  /// 삭제되었거나 더 이상 볼 수 없게 된 글인가.
  bool isHidden(Prayer? p) => p == null || (p.deleted && !me.isStaff);

  /// 타인의 글을 교역자가 지울 때는 사유를 반드시 기록한다.
  bool needsDeleteReason(Prayer p) =>
      !isAuthor(p) && _settings.requireDeleteReason;

  /// 비공개 글을 열었을 때: 작성자는 답변 확인을 표시하고,
  /// 교역자는 타인의 글 열람 기록을 남긴다. 실패해도 화면은 계속 보여준다.
  void _recordOpened(Prayer p) {
    if (p.isPublic) return;
    if (p.authorId == me.id) {
      if (p.hasUnreadResponse) {
        _prayers.markResponsesSeen(me.churchId, p.id).ignore();
      }
    } else if (me.isStaff && _settings.logPrivateAccess) {
      _prayers.logPrivateAccess(me.churchId, p.id).ignore();
    }
  }

  Future<bool> delete(Prayer p, {String? reason}) => run(
    () => isAuthor(p)
        ? _prayers.deleteOwn(me.churchId, p.id)
        : _prayers.deleteByStaff(me.churchId, p.id, reason ?? ''),
  );

  Future<bool> restore(Prayer p) =>
      run(() => _prayers.restore(me.churchId, p.id));

  Future<bool> addComment(Prayer p, String text) =>
      run(() => _prayers.addComment(me.churchId, p.id, text));

  Future<bool> addResponse(Prayer p, String text) =>
      run(() => _prayers.addResponse(me.churchId, p.id, text));
}
