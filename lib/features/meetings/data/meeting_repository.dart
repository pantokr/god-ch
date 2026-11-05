import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/app_exception.dart';
import '../../../data/firestore_paths.dart';
import '../../../data/models/app_notification.dart';
import '../../../data/models/meeting.dart';
import '../../../data/models/meeting_comment.dart';
import '../../../data/models/meeting_settings.dart';

import 'dart:typed_data';

import '../../auth/data/auth_repository.dart';
import '../../home/data/content_repository.dart';
import '../../notifications/data/activity_notice.dart';

/// 교회 모임을 읽고 쓴다 (`churches/{id}/meetings`). 교인이 모임을 만들면 모임장이 되고,
/// 다른 교인은 참여를 신청한다. 권한과 정원은 `firestore.rules`가 강제한다.
class MeetingRepository {
  MeetingRepository(FirebaseFirestore db, this._auth, this._contents)
    : _paths = FirestorePaths(db);

  final FirestorePaths _paths;
  final AuthRepository _auth;
  final ContentRepository _contents;

  /// 앱 운영자가 Storage `examples/example_image1.jpg` ~ `example_image7.jpg`에 올려 둔 임시 이미지 수.
  static const exampleCount = 7;

  final _examples = <int, Future<String?>>{};

  /// 썸네일이 없는 모임이 쓰는 임시 이미지 주소. 모임마다 같은 그림이 나오게 [seed]로 고른다.
  /// 파일이 없으면 null (색 면으로 보인다).
  Future<String?> exampleUrl(String seed) {
    var h = 0;
    for (final c in seed.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    final n = h % exampleCount + 1;
    return _examples[n] ??= _contents.downloadUrl(
      'examples/example_image$n.jpg',
    );
  }

  /// 모임 썸네일을 올리고 주소를 돌려준다 (`churches/{id}/meetings`).
  Future<String> uploadImage(String churchId, Uint8List bytes) =>
      _contents.uploadThumbnailTo(
        'churches/$churchId/meetings',
        bytes: bytes,
        size: 512,
      );

  CollectionReference<Map<String, dynamic>> _col(String churchId) =>
      _paths.meetings(churchId);

  DocumentReference<Map<String, dynamic>> _settings(String churchId) =>
      _paths.church(churchId).collection('settings').doc('meeting');

  /// 교회가 정한 모임 일정 운영 설정 (실시간). 정한 적 없으면 모두 허용 · 공개.
  Stream<MeetingSettings> settings(String churchId) =>
      _settings(churchId).snapshots().map(MeetingSettings.fromDoc);

  Future<MeetingSettings> loadSettings(String churchId) async =>
      MeetingSettings.fromDoc(await _settings(churchId).get());

  Future<void> saveSettings(String churchId, MeetingSettings settings) =>
      _settings(churchId).set(settings.toMap());

  /// 모임 날짜가 가까운 쪽이 위. 지워진 모임은 뺀다.
  Stream<List<Meeting>> latest(String churchId, {int limit = 100}) =>
      _col(churchId)
          .orderBy('date', descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (s) => [
              for (final d in s.docs)
                if (d.data()['deleted'] != true) Meeting.fromDoc(d),
            ],
          );

  /// 모임 한 건. 지워졌거나 없으면 null.
  Stream<Meeting?> one(String churchId, String id) =>
      _col(churchId).doc(id).snapshots().map((s) {
        if (!s.exists) return null;
        final m = Meeting.fromDoc(s);
        return m.deleted ? null : m;
      });

  String _check(
    String title,
    String description,
    String place,
    int capacity,
    int fee,
  ) {
    final t = title.trim();
    if (t.isEmpty) throw const AppException('제목을 입력해 주세요.');
    if (t.length > Meeting.maxTitle) {
      throw AppException('제목은 ${Meeting.maxTitle}자까지 쓸 수 있어요.');
    }
    if (description.trim().length > Meeting.maxDescription) {
      throw AppException('소개는 ${Meeting.maxDescription}자까지 쓸 수 있어요.');
    }
    if (place.trim().length > Meeting.maxPlace) {
      throw AppException('장소는 ${Meeting.maxPlace}자까지 쓸 수 있어요.');
    }
    if (capacity < 2 || capacity > Meeting.maxCapacity) {
      throw AppException('정원은 2명에서 ${Meeting.maxCapacity}명까지예요.');
    }
    if (fee < 0 || fee > Meeting.maxFee) {
      throw const AppException('회비를 확인해 주세요.');
    }
    return t;
  }

  /// 새 모임. 만든 사람이 모임장이고 첫 참여자다.
  Future<void> create(
    String churchId, {
    required String leaderName,
    required String title,
    required String description,
    required String place,
    required DateTime date,
    required int capacity,
    int fee = 0,
    bool needsApproval = false,
    String imageUrl = '',
  }) {
    final t = _check(title, description, place, capacity, fee);
    return _col(churchId).add({
      'imageUrl': imageUrl,
      'title': t,
      'description': description.trim(),
      'place': place.trim(),
      'date': Timestamp.fromDate(date),
      'capacity': capacity,
      'leaderId': _auth.uid,
      'leaderName': leaderName,
      'participantIds': <String>[],
      'pendingIds': <String>[],
      'fee': fee,
      'needsApproval': needsApproval,
      'likedBy': <String>[],
      'views': 0,
      'deleted': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 모임 내용을 고친다 (모임장 · 교역자). 정원은 이미 참여한 사람보다 적게 줄일 수 없다.
  Future<void> update(
    String churchId,
    Meeting m, {
    required String title,
    required String description,
    required String place,
    required DateTime date,
    required int capacity,
    int fee = 0,
    bool needsApproval = false,
    String imageUrl = '',
  }) {
    final t = _check(title, description, place, capacity, fee);
    if (capacity < m.joined) {
      throw AppException('이미 ${m.joined}명이 참여해서 정원을 그보다 줄일 수 없어요.');
    }
    return _col(churchId).doc(m.id).update({
      'imageUrl': imageUrl,
      'title': t,
      'description': description.trim(),
      'place': place.trim(),
      'date': Timestamp.fromDate(date),
      'capacity': capacity,
      'fee': fee,
      'needsApproval': needsApproval,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  CollectionReference<Map<String, dynamic>> _comments(
    String churchId,
    String meetingId,
  ) => _col(churchId).doc(meetingId).collection('comments');

  /// 일정의 댓글: 오래된 순. 지운 댓글도 `deleted` 표시와 함께 돌려준다 (답글이 달린 댓글의 자리를 남기기 위해).
  Stream<List<MeetingComment>> comments(String churchId, String meetingId) =>
      _comments(churchId, meetingId)
          .orderBy('createdAt')
          .snapshots()
          .map((s) => [for (final d in s.docs) MeetingComment.fromDoc(d)]);

  /// 내가 쓴 댓글만 읽는다 (댓글을 비공개로 둔 교회에서 일정 삭제 권한이 없는 교인이 쓴다).
  Stream<List<MeetingComment>> myComments(
    String churchId,
    String meetingId,
    String uid,
  ) => _comments(churchId, meetingId)
      .where('authorId', isEqualTo: uid)
      .snapshots()
      .map((s) => [for (final d in s.docs) MeetingComment.fromDoc(d)]);

  Future<void> addComment(
    String churchId,
    String meetingId, {
    required String authorName,
    required String text,
    String? parentId,
  }) {
    final t = text.trim();
    if (t.isEmpty) throw const AppException('댓글을 입력해 주세요.');
    if (t.length > MeetingComment.maxLength) {
      throw AppException('댓글은 ${MeetingComment.maxLength}자까지 쓸 수 있어요.');
    }
    return _addCommentAndNotify(churchId, meetingId, authorName, t, parentId);
  }

  /// 댓글을 쓰고, 모임장에게 "댓글" 알림을 같은 묶음으로 보낸다 (내 모임이면 보내지 않는다).
  Future<void> _addCommentAndNotify(
    String churchId,
    String meetingId,
    String authorName,
    String text,
    String? parentId,
  ) async {
    final meeting = await _col(churchId).doc(meetingId).get();
    final batch = _paths.db.batch()
      ..set(_comments(churchId, meetingId).doc(), {
        'authorId': _auth.uid,
        'authorName': authorName,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
        'parentId': ?parentId,
      });
    ActivityNotice.add(
      batch,
      _paths.db,
      me: _auth.uid,
      authorId: meeting.data()?['leaderId'] as String? ?? '',
      churchId: churchId,
      kind: ActivityNotice.meeting,
      postId: meetingId,
      postTitle: meeting.data()?['title'] as String? ?? '',
      actorName: authorName,
      comment: true,
    );
    await batch.commit();
  }

  /// 내 댓글의 내용을 고친다 (고친 시각이 남는다).
  Future<void> editComment(
    String churchId,
    String meetingId,
    String commentId,
    String text,
  ) {
    final t = text.trim();
    if (t.isEmpty) throw const AppException('댓글을 입력해 주세요.');
    if (t.length > MeetingComment.maxLength) {
      throw AppException('댓글은 ${MeetingComment.maxLength}자까지 쓸 수 있어요.');
    }
    return _comments(churchId, meetingId).doc(commentId).update({
      'text': t,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 댓글을 지운 것으로 표시한다 (기록 보관).
  Future<void> deleteComment(
    String churchId,
    String meetingId,
    String commentId,
  ) => _comments(churchId, meetingId).doc(commentId).update({
    'deleted': true,
    'deletedAt': FieldValue.serverTimestamp(),
    'deletedBy': _auth.uid,
  });

  /// 모임을 지운 것으로 표시한다 (기록 보관).
  Future<void> delete(String churchId, String id) => _col(churchId)
      .doc(id)
      .update({
        'deleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': _auth.uid,
      });

  /// 참여를 신청하거나 취소한다. 정원을 넘으면 규칙이 거부한다.
  /// 입장 조건이 모임장 승인이면 신청은 승인 대기([Meeting.pendingIds])에 들어가고, 모임장이 승인해야 참여자가 된다.
  /// 취소는 참여자이면 참여에서, 승인 대기 중이면 대기에서 뺀다.
  /// 승인이 필요한 모임에 신청하면 모임장의 알림(`users/{모임장}/notifications`)이 같은 묶음으로 만들어진다.
  Future<void> setJoined(
    String churchId,
    Meeting m, {
    required bool joined,
    String applicantName = '',
  }) {
    final needsApproval = joined && m.needsApproval && m.leaderId != _auth.uid;
    final field = joined
        ? (needsApproval ? 'pendingIds' : 'participantIds')
        : (m.joinedBy(_auth.uid) ? 'participantIds' : 'pendingIds');
    final change = {
      field: joined
          ? FieldValue.arrayUnion([_auth.uid])
          : FieldValue.arrayRemove([_auth.uid]),
    };
    final doc = _col(churchId).doc(m.id);
    if (!needsApproval) return doc.update(change);
    final batch = _paths.db.batch()..update(doc, change);
    batch.set(
      _paths.db
          .collection('users')
          .doc(m.leaderId)
          .collection('notifications')
          .doc(),
      joinRequestNotification(
        churchId: churchId,
        meeting: m,
        applicantName: applicantName,
      ),
    );
    return batch.commit();
  }

  /// 모임장에게 보낼 "참여 신청" 알림 문서. 모임장이 알림에서 눌러 그 모임을 열 수 있다.
  static Map<String, dynamic> joinRequestNotification({
    required String churchId,
    required Meeting meeting,
    required String applicantName,
  }) => {
    'type': NotificationType.meetingJoinRequest.name,
    'title': '참여 신청 · ${meeting.title}',
    'body': applicantName.isEmpty
        ? '승인을 기다리고 있어요.'
        : '$applicantName님이 승인을 기다리고 있어요.',
    'read': false,
    'churchId': churchId,
    'meetingId': meeting.id,
    'createdAt': FieldValue.serverTimestamp(),
  };

  /// 모임장이 승인 대기 중인 신청을 승인한다 (참여자로 옮긴다). 정원이 차면 규칙이 거부한다.
  Future<void> approve(String churchId, Meeting m, String uid) =>
      _col(churchId).doc(m.id).update({
        'participantIds': FieldValue.arrayUnion([uid]),
        'pendingIds': FieldValue.arrayRemove([uid]),
      });

  /// 모임장이 승인 대기 중인 신청을 거절한다.
  Future<void> reject(String churchId, Meeting m, String uid) =>
      _col(churchId).doc(m.id).update({
        'pendingIds': FieldValue.arrayRemove([uid]),
      });

  /// 모임장 · 교회 운영자가 참여자를 내보낸다.
  Future<void> kick(String churchId, Meeting m, String uid) =>
      _col(churchId).doc(m.id).update({
        'participantIds': FieldValue.arrayRemove([uid]),
      });

  /// 좋아요를 누르거나 취소한다. 누를 때 모임장에게 "좋아요" 알림이 같은 묶음으로 간다.
  Future<void> setLike(
    String churchId,
    String id, {
    required bool liked,
  }) async {
    final doc = _col(churchId).doc(id);
    final batch = _paths.db.batch()
      ..update(doc, {
        'likedBy': liked
            ? FieldValue.arrayUnion([_auth.uid])
            : FieldValue.arrayRemove([_auth.uid]),
      });
    if (liked) {
      final meeting = await doc.get();
      ActivityNotice.add(
        batch,
        _paths.db,
        me: _auth.uid,
        authorId: meeting.data()?['leaderId'] as String? ?? '',
        churchId: churchId,
        kind: ActivityNotice.meeting,
        postId: id,
        postTitle: meeting.data()?['title'] as String? ?? '',
        actorName: _auth.displayName,
        comment: false,
      );
    }
    await batch.commit();
  }

  Future<void> addView(String churchId, String id) =>
      _col(churchId).doc(id).update({'views': FieldValue.increment(1)});
}
