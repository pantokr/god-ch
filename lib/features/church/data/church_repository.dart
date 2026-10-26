import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/app_exception.dart';
import '../../../data/firestore_codec.dart';
import '../../../data/firestore_paths.dart';
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
        final list = s.docs.map(Member.fromDoc).toList();
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
  Stream<Member?> membership(String churchId) => _paths
      .members(churchId)
      .doc(_auth.uid)
      .snapshots()
      .map((s) => s.exists ? Member.fromDoc(s) : null);

  /// 교역자가 새 초대 코드를 만든다. 기존 코드는 그대로 두고 만료되게 둔다.
  /// [role]과 [departmentIds]는 이 코드로 들어오는 사람에게 그대로 적용된다.
  /// 교역자 역할의 코드는 교회 운영자만 만들 수 있다 (규칙이 막는다).
  Future<String> createInviteCode(
    String churchId,
    String churchName, {
    Role role = Role.member,
    List<String> departmentIds = const [],
    String recipient = '',
    Set<ProfileField> requiredFields = const {},
  }) async {
    if (role == Role.admin) {
      throw const AppException('교회 운영자는 초대 코드로 지정할 수 없어요.');
    }
    if (recipient.trim().length > 30) {
      throw const AppException('받는 분 이름은 30자까지 쓸 수 있어요.');
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
                recipient: recipient.trim(),
                requiredFields: requiredFields,
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
            if (toDate(d.data()['expiresAt']) != null)
              InviteCode(
                d.id,
                toDate(d.data()['expiresAt'])!,
                role: d.data()['role'] == Role.staff.name
                    ? Role.staff
                    : Role.member,
                departmentIds: List<String>.from(
                  d.data()['departmentIds'] as List? ?? const [],
                ),
                recipient: d.data()['recipient'] as String? ?? '',
                requiredFields: ProfileField.fromNames(
                  d.data()['requiredFields'] as List? ?? const [],
                ),
              ),
        ]..sort((a, b) => b.expiresAt.compareTo(a.expiresAt)),
      );

  Future<void> revokeInviteCode(String code) =>
      _paths.inviteCodes.doc(code).delete();

  /// 초대 코드로 입장을 신청한다. 만료되었거나 없는 코드는 같은 메시지로 거부한다.
  ///
  /// 초대 코드가 주소·생년월일을 필수로 요청하는데 회원 정보에 없으면 [MissingProfileFields]를 던진다.
  /// 그때 [address]·[birthDate]를 채워서 다시 부르면 회원 정보에 저장하고 신청한다.
  Future<void> requestJoinByCode(
    String input, {
    String address = '',
    String birthDate = '',
  }) async {
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
    // 코드를 만들 때 정한 역할과 부서가 그대로 신청에 담긴다. (예전 코드에는 없으므로 교인·부서 없음)
    final role = snap.data()!['role'] == Role.staff.name
        ? Role.staff
        : Role.member;
    final departmentIds = List<String>.from(
      snap.data()!['departmentIds'] as List? ?? const [],
    );
    final ref = _paths.members(churchId).doc(_auth.uid);
    if ((await ref.get()).exists) {
      throw const AppException('이미 이 교회에 가입했거나 신청한 상태입니다.');
    }
    // 가입할 때 받은 이름·전화번호를 교회에 제공한다 (제3자 제공 동의 기반).
    final profile = await _profiles.requireCurrent();
    final required = ProfileField.fromNames(
      snap.data()!['requiredFields'] as List? ?? const [],
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
    try {
      await ref.set(
        _memberData(
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
        ),
      );
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
      // 확인한 직후에 코드가 만료되었거나 폐기된 경우일 수 있다.
      throw const AppException(
        '입장 신청을 저장하지 못했어요. 초대 코드가 방금 만료되었는지 확인하고 다시 시도해 주세요.',
      );
    }
  }

  Json _inviteData(
    String churchId,
    String churchName, {
    required Role role,
    required List<String> departmentIds,
    required String recipient,
    required Set<ProfileField> requiredFields,
  }) => {
    'churchId': churchId,
    'churchName': churchName,
    'role': role.name,
    'departmentIds': departmentIds,
    'recipient': recipient,
    'requiredFields': [for (final f in requiredFields) f.name],
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
