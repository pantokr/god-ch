import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/app_exception.dart';
import '../../../data/firestore_codec.dart';
import '../../../data/firestore_paths.dart';
import '../../../data/models/invite_code.dart';
import '../../../data/models/member.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/profile_repository.dart';

/// 초대 코드 발급·사용(입장 신청)과 내 소속 교회 목록.
/// 교회 생성은 [ChurchRequestRepository]가 맡는다.
class ChurchRepository {
  ChurchRepository(FirebaseFirestore db, this._auth, this._profiles)
    : _paths = FirestorePaths(db);

  /// 초대 코드가 유효한 기간. 규칙은 최대 31일까지 허용한다.
  static const inviteValidity = Duration(days: 7);

  final FirestorePaths _paths;
  final AuthRepository _auth;
  final ProfileRepository _profiles;

  /// 내가 속하거나 신청한 모든 교회에서의 내 교인 정보.
  Stream<List<Member>> myMemberships() =>
      _paths.allMembers.where('uid', isEqualTo: _auth.uid).snapshots().map((s) {
        final list = s.docs.map(Member.fromDoc).toList();
        list.sort((a, b) => a.churchName.compareTo(b.churchName));
        return list;
      });

  /// 교역자가 새 초대 코드를 만든다. 기존 코드는 그대로 두고 만료되게 둔다.
  Future<String> createInviteCode(String churchId, String churchName) async {
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = _randomCode();
      try {
        await _paths.inviteCodes
            .doc(code)
            .set(_inviteData(churchId, churchName));
        return code;
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied' || attempt == 4) rethrow;
      }
    }
    throw const AppException('초대 코드를 만들지 못했습니다.');
  }

  /// 이 교회의 초대 코드 목록 (만료된 것 포함, 최근 만료 순).
  Stream<List<InviteCode>> inviteCodes(String churchId) => _paths.inviteCodes
      .where('churchId', isEqualTo: churchId)
      .snapshots()
      .map(
        (s) => [
          for (final d in s.docs)
            if (toDate(d.data()['expiresAt']) != null)
              InviteCode(d.id, toDate(d.data()['expiresAt'])!),
        ]..sort((a, b) => b.expiresAt.compareTo(a.expiresAt)),
      );

  Future<void> revokeInviteCode(String code) =>
      _paths.inviteCodes.doc(code).delete();

  /// 초대 코드로 입장을 신청한다. 만료되었거나 없는 코드는 같은 메시지로 거부한다.
  Future<void> requestJoinByCode(String input) async {
    final code = input.trim().toUpperCase();
    if (code.isEmpty) throw const AppException('초대 코드를 입력해 주세요.');

    const invalid = AppException('유효하지 않거나 만료된 초대 코드입니다.');
    DocumentSnapshot<Json> snap;
    try {
      snap = await _paths.inviteCodes.doc(code).get();
    } on FirebaseException catch (e) {
      // 만료된 코드는 규칙에서 조회 자체가 거부된다.
      if (e.code == 'permission-denied') throw invalid;
      rethrow;
    }
    if (!snap.exists) throw invalid;

    final churchId = snap.data()!['churchId'] as String;
    final churchName = snap.data()!['churchName'] as String;
    final ref = _paths.members(churchId).doc(_auth.uid);
    if ((await ref.get()).exists) {
      throw const AppException('이미 이 교회에 가입했거나 신청한 상태입니다.');
    }
    // 가입할 때 받은 이름·전화번호를 교회에 제공한다 (제3자 제공 동의 기반).
    final profile = await _profiles.requireCurrent();
    try {
      await ref.set(
        _memberData(
          churchId: churchId,
          churchName: churchName,
          name: profile.name,
          phone: profile.phone,
          role: Role.member,
          status: MemberStatus.pending,
          inviteCode: code,
        ),
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') throw invalid;
      rethrow;
    }
  }

  Json _inviteData(String churchId, String churchName) => {
    'churchId': churchId,
    'churchName': churchName,
    'createdBy': _auth.uid,
    'expiresAt': Timestamp.fromDate(DateTime.now().add(inviteValidity)),
  };

  Json _memberData({
    required String churchId,
    required String churchName,
    required String name,
    required String phone,
    required Role role,
    required MemberStatus status,
    String? inviteCode,
  }) => {
    'uid': _auth.uid,
    'churchId': churchId,
    'churchName': churchName,
    'name': name,
    'email': _auth.email.toLowerCase(),
    'phone': phone,
    'role': role.name,
    'status': status.name,
    'departmentIds': <String>[],
    'createdAt': FieldValue.serverTimestamp(),
    // 입장 신청에 쓴 초대 코드. 규칙이 유효기간을 검사한다.
    'inviteCode': ?inviteCode,
  };

  /// 읽기 쉬운 문자만 쓴 8자리 코드 (0/O, 1/I 제외).
  String _randomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    return List.generate(8, (_) => chars[rnd.nextInt(chars.length)]).join();
  }
}
