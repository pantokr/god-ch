import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/app_exception.dart';
import '../../../data/firestore_codec.dart';
import '../../../data/firestore_paths.dart';
import '../../../data/models/church.dart';
import '../../../data/models/invite_code.dart';
import '../../../data/models/member.dart';
import '../../../data/models/profile_field.dart';
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
        final list = s.docs
            .map(Member.fromDoc)
            .where((m) => m.status != MemberStatus.removed)
            .toList();
        list.sort((a, b) => a.churchName.compareTo(b.churchName));
        return list;
      });

  String get _lastChurchKey => 'lastChurch.${_auth.uid}';

  /// 마지막으로 들어간 교회. 로그인하면 소속 교회가 여럿일 때 이 교회로 바로 간다.
  Future<String?> lastChurchId() async {
    try {
      return (await SharedPreferences.getInstance()).getString(_lastChurchKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> rememberChurch(String churchId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastChurchKey, churchId);
    } catch (_) {
      // 기억하지 못해도 앱은 그대로 쓸 수 있다.
    }
  }

  /// 한 교회에서의 내 교인 정보. 입장을 신청한 적이 없으면 null.
  Stream<Member?> membership(String churchId) =>
      _paths.members(churchId).doc(_auth.uid).snapshots().map((s) {
        if (!s.exists) return null;
        final m = Member.fromDoc(s);
        // 추방된 교인은 기록만 남아 있을 뿐 교인이 아니다.
        return m.status == MemberStatus.removed ? null : m;
      });

  /// 교역자가 새 초대 코드를 만든다. 기존 코드는 그대로 두고 만료되게 둔다.
  /// [role]과 [departmentIds]는 이 코드로 들어오는 사람에게 그대로 적용된다.
  /// 교역자 역할의 코드는 교회 운영자만 만들 수 있다 (규칙이 막는다).
  Future<String> createInviteCode(
    String churchId,
    String churchName, {
    Role role = Role.member,
    List<String> departmentIds = const [],
    bool singleUse = false,
  }) async {
    if (role == Role.admin) {
      throw const AppException('교회 운영자는 초대 코드로 지정할 수 없어요.');
    }
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = _randomCode();
      try {
        await _paths.inviteCodes
            .doc(code)
            .set(
              _inviteData(
                churchId,
                churchName,
                role: role,
                departmentIds: departmentIds,
                singleUse: singleUse,
              ),
            );
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
            // 폐기되었거나 이미 쓰인 코드는 기록으로만 남는다.
            if (toDate(d.data()['expiresAt']) != null &&
                d.data()['revoked'] != true &&
                (d.data()['usedBy'] as String? ?? '').isEmpty)
              InviteCode(
                d.id,
                toDate(d.data()['expiresAt'])!,
                role: d.data()['role'] == Role.staff.name
                    ? Role.staff
                    : Role.member,
                departmentIds: List<String>.from(
                  d.data()['departmentIds'] as List? ?? const [],
                ),
                singleUse: d.data()['singleUse'] == true,
              ),
        ]..sort((a, b) => b.expiresAt.compareTo(a.expiresAt)),
      );

  DocumentReference<Json> _joinSettings(String churchId) =>
      _paths.church(churchId).collection('settings').doc('join');

  /// 이 교회가 입장 신청에 필수로 요청하는 회원 정보.
  Stream<Set<ProfileField>> joinRequirements(String churchId) =>
      _joinSettings(churchId).snapshots().map(
        (s) => ProfileField.fromNames(
          s.data()?['requiredFields'] as List? ?? const [],
        ),
      );

  Future<void> setJoinRequirements(String churchId, Set<ProfileField> fields) =>
      _joinSettings(churchId).set({
        'requiredFields': [for (final f in fields) f.name],
      });

  /// 코드를 폐기한 것으로 표시한다 (문서는 남긴다).
  Future<void> revokeInviteCode(String code) =>
      _paths.inviteCodes.doc(code).update({
        'revoked': true,
        'revokedAt': FieldValue.serverTimestamp(),
        'revokedBy': _auth.uid,
      });

  /// 초대 코드로 입장을 신청한다. 만료되었거나 없는 코드는 같은 메시지로 거부한다.
  ///
  /// 교회가 입장 시 주소·생년월일을 필수로 요청하는데 회원 정보에 없으면 [MissingProfileFields]를 던진다.
  /// 그때 [address]·[birthDate]를 채워서 다시 부르면 회원 정보에 저장하고 신청한다.
  Future<void> requestJoinByCode(
    String input, {
    String address = '',
    String birthDate = '',
  }) async {
    final code = input.trim().toUpperCase();
    if (code.isEmpty) throw const AppException('초대 코드를 입력해 주세요.');
    if (await _auth.hasOperatorClaim()) {
      throw const AppException('앱 운영자는 교회 회원이 될 수 없어요.');
    }

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
    final used = (snap.data()!['usedBy'] as String? ?? '').isNotEmpty;
    if (used || snap.data()!['revoked'] == true) throw invalid;

    final churchId = snap.data()!['churchId'] as String;
    final churchName = snap.data()!['churchName'] as String;
    // 코드를 만들 때 정한 역할과 부서가 그대로 신청에 담긴다. (예전 코드에는 없으므로 교인·부서 없음)
    final role = snap.data()!['role'] == Role.staff.name
        ? Role.staff
        : Role.member;
    final departmentIds = List<String>.from(
      snap.data()!['departmentIds'] as List? ?? const [],
    );
    final singleUse = snap.data()!['singleUse'] == true;
    try {
      await _submitJoin(
        churchId: churchId,
        churchName: churchName,
        role: role,
        departmentIds: departmentIds,
        address: address,
        birthDate: birthDate,
        code: code,
        // 일회용 코드는 신청과 같은 묶음에서 '사용됨'으로 표시한다. 동시에 두 사람이 써도 한 사람만 성공한다.
        consume: singleUse ? snap.reference : null,
      );
    } on _CodeGone {
      throw invalid;
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
      // 확인한 직후에 코드가 만료되었거나 폐기된 경우일 수 있다.
      throw const AppException(
        '입장 신청을 저장하지 못했어요. 초대 코드가 방금 만료되었는지 확인하고 다시 시도해 주세요.',
      );
    }
  }

  /// 공개 탐색에 노출된 교회를 찾는다 (이름 순).
  Stream<List<Church>> publicChurches() => _paths.churches
      .where('listed', isEqualTo: true)
      .snapshots()
      .map(
        (s) =>
            s.docs.map(Church.fromDoc).where((c) => !c.closed).toList()
              ..sort((a, b) => a.name.compareTo(b.name)),
      );

  /// 노출된 교회에 초대 코드 없이 입장을 요청한다. 승인되면 교인이 된다.
  /// 필수 정보가 비어 있으면 [MissingProfileFields]를 던지고, 채워서 다시 부르면 된다.
  Future<void> requestJoinPublic(
    Church church, {
    String address = '',
    String birthDate = '',
  }) async {
    if (await _auth.hasOperatorClaim()) {
      throw const AppException('앱 운영자는 교회 회원이 될 수 없어요.');
    }
    try {
      await _submitJoin(
        churchId: church.id,
        churchName: church.name,
        role: Role.member,
        departmentIds: const [],
        address: address,
        birthDate: birthDate,
      );
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
      throw const AppException('입장 요청을 저장하지 못했어요. 이 교회가 더는 공개 탐색에 없을 수 있어요.');
    }
  }

  /// 이 교회가 폐쇄되었는가 (소속 교인이 읽을 수 있다).
  Stream<bool> isClosed(String churchId) => _paths
      .church(churchId)
      .snapshots()
      .map((s) => s.data()?['closed'] == true);

  /// 이 교회가 공개 탐색에 노출되는가 (교역자가 입장 관리에서 정한다).
  Stream<bool> isListed(String churchId) => _paths
      .church(churchId)
      .snapshots()
      .map((s) => s.data()?['listed'] == true);

  Future<void> setListed(String churchId, bool listed) =>
      _paths.church(churchId).update({'listed': listed});

  /// 입장 신청을 저장한다 (초대 코드든 공개 요청이든 같은 절차).
  /// [consume]이 있으면 그 문서(일회용 초대 코드)를 같은 묶음에서 사용됨으로 표시한다.
  Future<void> _submitJoin({
    required String churchId,
    required String churchName,
    required Role role,
    required List<String> departmentIds,
    required String address,
    required String birthDate,
    String? code,
    DocumentReference<Json>? consume,
  }) async {
    final ref = _paths.members(churchId).doc(_auth.uid);
    final blocked = await _paths.blocked(churchId).doc(_auth.uid).get();
    if (blocked.exists && blocked.data()?['revoked'] != true) {
      throw const AppException('이 교회에 접근할 수 없어요. 차단된 계정입니다.');
    }
    final current = await ref.get();
    // 추방된 사람은 다시 신청할 수 있다 (같은 문서를 새 신청으로 덮는다).
    if (current.exists &&
        current.data()?['status'] != MemberStatus.removed.name) {
      throw const AppException('이미 이 교회에 가입했거나 신청한 상태입니다.');
    }
    // 가입할 때 받은 이름·전화번호를 교회에 제공한다 (제3자 제공 동의 기반).
    final profile = await _profiles.requireCurrent();
    final settings = await _joinSettings(churchId).get();
    final required = ProfileField.fromNames(
      settings.data()?['requiredFields'] as List? ?? const [],
    );
    final nextAddress = address.trim().isNotEmpty
        ? address.trim()
        : profile.address;
    final nextBirthDate = birthDate.trim().isNotEmpty
        ? birthDate.trim()
        : profile.birthDate;
    final missing = {
      if (required.contains(ProfileField.address) && nextAddress.isEmpty)
        ProfileField.address,
      if (required.contains(ProfileField.birthDate) && nextBirthDate.isEmpty)
        ProfileField.birthDate,
    };
    if (missing.isNotEmpty) throw MissingProfileFields(churchName, missing);
    // 새로 입력한 정보는 회원 정보에도 저장해 다른 교회에서 다시 묻지 않게 한다.
    if (nextAddress != profile.address || nextBirthDate != profile.birthDate) {
      await _profiles.saveExtra(address: nextAddress, birthDate: nextBirthDate);
    }
    final member = _memberData(
      churchId: churchId,
      churchName: churchName,
      name: profile.name,
      phone: profile.phone,
      loginId: profile.loginId ?? '',
      photoUrl: profile.photoUrl,
      address: nextAddress,
      birthDate: nextBirthDate,
      role: role,
      status: MemberStatus.pending,
      departmentIds: departmentIds,
      inviteCode: code,
    );
    await _paths.db.runTransaction((tx) async {
      if (consume != null) {
        final code = await tx.get(consume);
        if (!code.exists ||
            code.data()?['revoked'] == true ||
            (code.data()?['usedBy'] as String? ?? '').isNotEmpty) {
          throw _CodeGone();
        }
        tx.update(consume, {
          'usedBy': _auth.uid,
          'usedAt': FieldValue.serverTimestamp(),
        });
      }
      tx.set(ref, member);
    });
  }

  Json _inviteData(
    String churchId,
    String churchName, {
    required Role role,
    required List<String> departmentIds,
    required bool singleUse,
  }) => {
    'churchId': churchId,
    'churchName': churchName,
    'role': role.name,
    'departmentIds': departmentIds,
    'singleUse': singleUse,
    'createdBy': _auth.uid,
    'expiresAt': Timestamp.fromDate(DateTime.now().add(inviteValidity)),
  };

  Json _memberData({
    required String churchId,
    required String churchName,
    required String name,
    required String phone,
    String loginId = '',
    String photoUrl = '',
    String address = '',
    String birthDate = '',
    required Role role,
    required MemberStatus status,
    List<String> departmentIds = const [],
    String? inviteCode,
  }) => {
    'uid': _auth.uid,
    'churchId': churchId,
    'churchName': churchName,
    'name': name,
    'phone': phone,
    if (loginId.isNotEmpty) 'loginId': loginId,
    if (photoUrl.isNotEmpty) 'photoUrl': photoUrl,
    if (address.isNotEmpty) 'address': address,
    if (birthDate.isNotEmpty) 'birthDate': birthDate,
    'role': role.name,
    'status': status.name,
    'departmentIds': departmentIds,
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

/// 초대 코드가 필수로 요청한 회원 정보가 비어 있다. 화면에서 [fields]를 입력받아 다시 신청한다.
class MissingProfileFields extends AppException {
  MissingProfileFields(this.churchName, this.fields)
    : super('$churchName에서 ${fields.map((f) => f.label).join('·')} 입력을 요청했어요.');

  final String churchName;
  final Set<ProfileField> fields;
}

/// 일회용 초대 코드를 다른 사람이 먼저 써서 사라졌다.
class _CodeGone implements Exception {}
