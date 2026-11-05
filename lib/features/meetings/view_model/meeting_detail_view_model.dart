import 'dart:typed_data';

import 'dart:async';

import '../../../core/mvvm/view_model.dart';
import '../../../data/models/meeting.dart';
import '../../../data/models/meeting_settings.dart';
import '../data/meeting_repository.dart';
import '../view/meeting_form.dart';

/// 모임 상세: 모임 한 건(실시간), 참여 신청 · 취소, 좋아요, 수정 · 삭제. 열 때 조회수를 하나 올린다.
class MeetingDetailViewModel extends ViewModel {
  MeetingDetailViewModel(this._repo, this.churchId, this.id)
    : meeting = _repo.one(churchId, id) {
    // 조회수 기록이 실패해도 글을 보는 데는 영향이 없다.
    _repo.addView(churchId, id).catchError((Object _) {});
    _settingsSub = _repo.settings(churchId).listen((v) {
      settings = v;
      notifyListeners();
    }, onError: (_) {});
  }

  late final StreamSubscription<MeetingSettings> _settingsSub;

  /// 교회가 정한 모임 일정 운영 설정 (좋아요 · 댓글 · 조회수). 정한 적 없으면 모두 허용 · 공개.
  MeetingSettings settings = MeetingSettings.standard;

  @override
  void dispose() {
    _settingsSub.cancel();
    super.dispose();
  }

  final MeetingRepository _repo;
  final String churchId;
  final String id;
  final Stream<Meeting?> meeting;

  Future<bool> setJoined(Meeting m, bool joined, {String applicantName = ''}) =>
      run(
        () => _repo.setJoined(
          churchId,
          m,
          joined: joined,
          applicantName: applicantName,
        ),
      );

  /// 모임장이 승인 대기 중인 신청을 승인하거나 거절한다.
  Future<bool> approve(Meeting m, String uid) =>
      run(() => _repo.approve(churchId, m, uid), blocking: false);

  Future<bool> kick(Meeting m, String uid) =>
      run(() => _repo.kick(churchId, m, uid), blocking: false);

  Future<bool> reject(Meeting m, String uid) =>
      run(() => _repo.reject(churchId, m, uid), blocking: false);

  Future<bool> setLike(bool liked) =>
      run(() => _repo.setLike(churchId, id, liked: liked), blocking: false);

  Future<bool> update(Meeting m, MeetingFormResult v) => run(
    () => _repo.update(
      churchId,
      m,
      title: v.title,
      description: v.description,
      place: v.place,
      date: v.date,
      capacity: v.capacity,
      fee: v.fee,
      needsApproval: v.needsApproval,
      imageUrl: v.imageUrl,
    ),
  );

  Future<String?> uploadImage(String fileName, Uint8List bytes) async {
    String? url;
    await run(() async => url = await _repo.uploadImage(churchId, bytes));
    return url;
  }

  Future<bool> delete() => run(() => _repo.delete(churchId, id));
}
