import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/app_exception.dart';
import '../../../data/firestore_paths.dart';
import '../../../data/models/app_notification.dart';
import '../../../data/models/church_request.dart';
import '../../../data/models/member.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/profile_repository.dart';

/// 교회 생성 요청: 누구나 요청하고, 앱 운영자가 승인하면 교회가 만들어진다.
class ChurchRequestRepository {
  ChurchRequestRepository(FirebaseFirestore db, this._auth, this._profiles)
    : _db = db,
      _paths = FirestorePaths(db);

  final FirebaseFirestore _db;
  final FirestorePaths _paths;
  final AuthRepository _auth;
  final ProfileRepository _profiles;

  // ---- 요청하는 사람 ----

  /// 한 사람이 낼 수 있는 교회 생성 요청 수 (거절된 요청은 세지 않는다).
  static const maxPerPerson = 3;

  /// 교회 생성을 요청한다. 앱 운영자가 승인할 때까지 교회는 만들어지지 않는다.
  Future<void> request({
    required String name,
    required String phone,
    required String address,
  }) async {
    if (name.trim().isEmpty) throw const AppException('교회 이름을 입력해 주세요.');
    if (phone.trim().isEmpty) throw const AppException('교회 전화번호를 입력해 주세요.');
    if (address.trim().isEmpty) throw const AppException('교회 주소를 입력해 주세요.');
    final profile = await _profiles.requireCurrent();
    final mine = await _paths.churchRequests
        .where('requesterId', isEqualTo: _auth.uid)
        .get();
    final used = mine.docs
        .where((d) => d.data()['status'] != RequestStatus.rejected.name)
        .length;
    if (used >= maxPerPerson) {
      throw const AppException('교회 생성 요청은 한 사람당 3개까지 할 수 있어요.');
    }
    await _paths.churchRequests.add({
      'requesterId': _auth.uid,
      'requesterName': profile.name,
      'requesterPhone': profile.phone,
      'name': name.trim(),
      'phone': phone.trim(),
      'address': address.trim(),
      'status': RequestStatus.pending.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 내가 보낸 요청 (최근 순). 복합 인덱스를 피하려고 정렬은 앱에서 한다.
  Stream<List<ChurchRequest>> myRequests() => _paths.churchRequests
      .where('requesterId', isEqualTo: _auth.uid)
      .snapshots()
      .map((s) => _newestFirst(s.docs.map(ChurchRequest.fromDoc)));

  // ---- 앱 운영자 ----

  /// 내가 앱 운영자인가. 운영자 문서가 없거나 읽을 수 없으면 false.
  Stream<bool> isPlatformAdmin() async* {
    // 운영자 계정은 클레임으로 바로 알 수 있다. 없으면 admins 문서를 확인한다.
    if (await _auth.hasOperatorClaim()) {
      yield true;
      return;
    }
    try {
      await for (final s in _paths.admins.doc(_auth.uid).snapshots()) {
        yield s.exists;
      }
    } catch (_) {
      yield false;
    }
  }

  /// 승인 대기 중인 모든 요청 (운영자 전용).
  Stream<List<ChurchRequest>> pendingRequests() => _paths.churchRequests
      .where('status', isEqualTo: RequestStatus.pending.name)
      .snapshots()
      .map((s) => _newestFirst(s.docs.map(ChurchRequest.fromDoc)));

  /// 요청을 승인한다. 요청 ID와 같은 ID로 교회를 만들고, 요청자를 교회 운영자로 등록한다.
  Future<void> approve(ChurchRequest r) async {
    // 요청자의 로그인 아이디 · 이메일을 교인 정보에도 남겨 회원 목록에서 알아볼 수 있게 한다.
    final profile = (await _db.collection('users').doc(r.requesterId).get())
        .data();
    final loginId = profile?['loginId'] as String? ?? '';
    final email = profile?['email'] as String? ?? '';
    final batch = _db.batch();
    batch.set(_paths.church(r.id), {
      'name': r.name,
      'phone': r.phone,
      'address': r.address,
      'createdBy': r.requesterId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(_paths.members(r.id).doc(r.requesterId), {
      'uid': r.requesterId,
      'churchId': r.id,
      'churchName': r.name,
      'name': r.requesterName,
      if (r.requesterPhone.isNotEmpty) 'phone': r.requesterPhone,
      if (loginId.isNotEmpty) 'loginId': loginId,
      if (email.isNotEmpty) 'email': email,
      'role': Role.admin.name,
      'status': MemberStatus.approved.name,
      'affiliationIds': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(_paths.churchRequests.doc(r.id), {
      'status': RequestStatus.approved.name,
      'churchId': r.id,
      'reviewedBy': _auth.uid,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  /// 요청을 거절하고, 요청자의 알림 탭에 거절 알림을 남긴다.
  Future<void> reject(ChurchRequest r, String reason) {
    final why = reason.trim();
    final batch = _db.batch();
    batch.update(_paths.churchRequests.doc(r.id), {
      'status': RequestStatus.rejected.name,
      'rejectReason': why,
      'reviewedBy': _auth.uid,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      _db
          .collection('users')
          .doc(r.requesterId)
          .collection('notifications')
          .doc(),
      {
        'type': NotificationType.churchRejected.name,
        'title': '${r.name} 교회 생성 요청이 거절되었어요',
        'body': why.isEmpty ? '운영자가 요청을 거절했어요.' : '사유: $why',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
    return batch.commit();
  }

  List<ChurchRequest> _newestFirst(Iterable<ChurchRequest> items) {
    final list = items.toList();
    list.sort(
      (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
        a.createdAt ?? DateTime.now(),
      ),
    );
    return list;
  }
}
