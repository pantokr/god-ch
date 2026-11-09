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
    this.permissionScopes = const {},
    this.rolePermissions = RolePermissions.defaults,
    this.createdAt,
    this.approvedAt,
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

  /// 직급에서 복사된 권한 범위 (권한 키 → 소속 ID들, `@mine` = 내가 속한 소속). 없으면 제한 없음.
  final Map<String, Set<String>> permissionScopes;

  /// 교회가 기본 직급(교역자 · 회원)에 정한 권한. 저장되는 값이 아니라 교인 정보를 읽을 때 함께 붙인다.
  final RolePermissions rolePermissions;
  final Role role;
  final MemberStatus status;

  final DateTime? createdAt;

  /// 입장을 수락한 시각 (교회 회원으로서의 시작일). 예전 교인은 없고, 그때는 [createdAt]을 쓴다.
  final DateTime? approvedAt;

  /// 회원 목록에 보이는 시작일: 수락한 시각, 없으면 신청한 시각.
  DateTime? get memberSince => approvedAt ?? createdAt;

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
    if (p.inKeys(permissions)) return true;
    return switch (role) {
      Role.staff => rolePermissions.staffHas(p),
      Role.member => rolePermissions.memberHas(p),
      Role.admin => true,
    };
  }

  /// 이 권한의 범위: 비어 있으면 전체(타인의 것까지), `@mine`이 있으면 본인만(본인이 쓴 것 · 만든 것만).
  /// 직급으로 받은 권한이면 그 직급의 범위, 교역자 · 회원 기본 권한이면 그 기본 직급에 정한 범위다.
  /// 정한 적이 없을 때 교인의 글 관리 · 반응 · 댓글 관리는 본인만이다.
  Set<String> scopeOf(Permission p) {
    if (role == Role.admin) return const {};
    if (p.inKeys(permissions)) {
      return permissionScopes[p.key] ?? const {};
    }
    final scopes = switch (role) {
      Role.staff => rolePermissions.staffScopes,
      Role.member => rolePermissions.memberScopes,
      Role.admin => null,
    };
    if (scopes != null) {
      return scopes[p.key] ?? const {};
    }
    return role == Role.member && p.memberOwnOnly
        ? const {scopeMine}
        : const {};
  }

  /// 이 권한이 있고 범위가 "전체"인가: 타인의 글 · 댓글 · 일정까지 다룰 수 있다. 본인만이면 false다.
  /// 교회 관리자는 늘 true다.
  bool canAll(Permission p) => can(p) && !scopeOf(p).contains(scopeMine);

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
    permissionScopes: permissionScopes,
    rolePermissions: r,
    createdAt: createdAt,
    approvedAt: approvedAt,
    isOperatorView: isOperatorView,
  );

  /// 중보기도 댓글을 쓸 수 있는가: 댓글 작성 권한이 있는 교역자, 또는 직급으로 그 권한을 받은 교인 (회원 기본은 반응까지).
  bool get canPrayerComment => can(Permission.prayerEngage);

  /// "미배정": 속한 곳이 하나도 없다 (소속도 직급도 없다). 하나라도 있으면 미배정이 아니다.
  bool get isUnassigned => affiliationIds.isEmpty && positionId == null;

  /// 관리 메뉴(인원 · 입장 · 소속)를 쓸 수 있는가: 교역자 이상이거나 관련 권한이 있다.
  bool get canManage =>
      isStaff ||
      can(Permission.memberManage) ||
      can(Permission.affiliationEdit);

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
      permissionScopes: readScopes(d['permissionScopes']),
      createdAt: toDate(d['createdAt']),
      approvedAt: toDate(d['approvedAt']),
    );
  }
}
