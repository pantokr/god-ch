import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_codec.dart';
import 'permission.dart';
import 'position.dart';

enum Role { member, staff, admin }

/// removed: 추방된 교인. 문서는 지우지 않고 남기며(기록 보관), 어디서도 교인으로 보이지 않는다.
enum MemberStatus { pending, approved, disabled, removed }

/// 한 교회 안에서의 교인 정보. 같은 사람이라도 교회마다 역할·승인 상태가 따로 있다.
class Member {
  const Member({
    required this.id,
    required this.churchId,
    required this.churchName,
    required this.name,
    required this.role,
    required this.status,
    this.phone = '',
    this.loginId = '',
    this.email = '',
    this.address = '',
    this.birthDate = '',
    this.photoUrl = '',
    this.affiliationIds = const [],
    this.positionId,
    this.permissions = const [],
    this.rolePermissions = RolePermissions.defaults,
    this.createdAt,
    this.isOperatorView = false,
  });

  /// 사용자(uid)와 같다.
  final String id;
  final String churchId;
  final String churchName;
  final String name;

  /// 가입할 때 받은 전화번호 (교회에 제공하는 것에 동의한 정보).
  final String phone;

  /// 로그인 아이디. 입장을 신청할 때 회원 프로필에서 가져온다 (Google 계정은 없다).
  final String loginId;

  /// Google 계정의 이메일 (ID로 가입한 교인은 없다).
  final String email;

  /// 입장을 신청할 때 회원 프로필에서 가져온 정보 (선택 입력).
  final String address;
  final String birthDate;

  /// 프로필 사진 주소 (회원 정보에서 복사).
  final String photoUrl;

  /// 속한 소속들 (여러 개일 수 있다). 교역자 · 교회 운영자만 정하고, 교인은 스스로 고를 수 없다.
  final List<String> affiliationIds;

  /// 받은 직급과, 그 직급에서 복사된 권한의 키들 ([Permission.key]). 교회 관리자만 정한다.
  final String? positionId;
  final List<String> permissions;

  /// 교회가 기본 직급(교역자 · 회원)에 정한 권한. 저장되는 값이 아니라 교인 정보를 읽을 때 함께 붙인다.
  final RolePermissions rolePermissions;
  final Role role;
  final MemberStatus status;

  final DateTime? createdAt;

  /// 앱 개발자가 교회를 열었을 때 화면용으로 만든 정보인가. 저장되지 않으며 소속을 뜻하지 않는다.
  /// 교회 관리자와 같은 화면과 권한을 보지만 회원은 아니다.
  final bool isOperatorView;

  /// 앱 개발자(admin 계정)의 교인 문서인가. 앱 운영자는 교회 회원이 아니므로 교인 목록에 나오지 않는다.
  /// (admin 계정은 uid `app-operator-admin`, 로그인 ID `admin`.)
  bool get isAppOperator => id == 'app-operator-admin' || loginId == 'admin';

  bool get isApproved => status == MemberStatus.approved;
  bool get isStaff => isApproved && role != Role.member;
  bool get isAdmin => isApproved && role == Role.admin;

  /// 이 권한이 있는가: 교회 관리자는 모두, 교역자는 기본 권한, 그리고 직급으로 받은 권한.
  bool can(Permission p) {
    if (!isApproved) return false;
    if (role == Role.admin) return true; // 교회 총괄 관리자: 그 교회의 절대 권한
    if (!p.grantable) return role == Role.staff && p.staffDefault;
    if (permissions.contains(p.key)) return true;
    return switch (role) {
      Role.staff => rolePermissions.staffHas(p),
      Role.member => rolePermissions.memberHas(p),
      Role.admin => true,
    };
  }

  /// 기본 직급 권한을 붙인 복사본.
  Member withRolePermissions(RolePermissions r) => Member(
    id: id,
    churchId: churchId,
    churchName: churchName,
    name: name,
    role: role,
    status: status,
    phone: phone,
    loginId: loginId,
    address: address,
    birthDate: birthDate,
    photoUrl: photoUrl,
    affiliationIds: affiliationIds,
    positionId: positionId,
    permissions: permissions,
    rolePermissions: r,
    createdAt: createdAt,
    isOperatorView: isOperatorView,
  );

  /// 중보기도 댓글을 쓸 수 있는가: 교역자, 또는 직급으로 댓글 권한을 직접 받은 교인 (회원 기본은 좋아요까지).
  bool get canPrayerComment =>
      can(Permission.prayerInteract) &&
      (isStaff || permissions.contains(Permission.prayerInteract.key));

  /// 관리 메뉴(인원 · 입장 · 소속)를 쓸 수 있는가: 교역자 이상이거나 관련 권한이 있다.
  bool get canManage =>
      isStaff ||
      can(Permission.memberApprove) ||
      can(Permission.inviteManage) ||
      can(Permission.affiliationAssign);

  factory Member.fromDoc(DocumentSnapshot<Json> doc) {
    final d = doc.data() ?? const {};
    return Member(
      id: doc.id,
      churchId: d['churchId'] as String? ?? '',
      churchName: d['churchName'] as String? ?? '',
      name: d['name'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
      loginId: d['loginId'] as String? ?? '',
      email: d['email'] as String? ?? '',
      address: d['address'] as String? ?? '',
      birthDate: d['birthDate'] as String? ?? '',
      photoUrl: d['photoUrl'] as String? ?? '',
      role: enumByName(Role.values, d['role'], Role.member),
      status: enumByName(
        MemberStatus.values,
        d['status'],
        MemberStatus.pending,
      ),
      affiliationIds: List<String>.from(
        d['affiliationIds'] as List? ?? const [],
      ),
      positionId: d['positionId'] as String?,
      permissions: List<String>.from(d['permissions'] as List? ?? const []),
      createdAt: toDate(d['createdAt']),
    );
  }
}
