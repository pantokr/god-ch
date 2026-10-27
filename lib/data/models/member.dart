import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_codec.dart';

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
    this.address = '',
    this.birthDate = '',
    this.photoUrl = '',
    this.departmentIds = const [],
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

  /// 입장을 신청할 때 회원 프로필에서 가져온 정보 (선택 입력).
  final String address;
  final String birthDate;

  /// 프로필 사진 주소 (회원 정보에서 복사).
  final String photoUrl;
  final Role role;
  final MemberStatus status;

  /// 내가 소속을 선택한 부서 (선택 사항, 비어 있어도 된다).
  final List<String> departmentIds;
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

  factory Member.fromDoc(DocumentSnapshot<Json> doc) {
    final d = doc.data() ?? const {};
    return Member(
      id: doc.id,
      churchId: d['churchId'] as String? ?? '',
      churchName: d['churchName'] as String? ?? '',
      name: d['name'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
      loginId: d['loginId'] as String? ?? '',
      address: d['address'] as String? ?? '',
      birthDate: d['birthDate'] as String? ?? '',
      photoUrl: d['photoUrl'] as String? ?? '',
      role: enumByName(Role.values, d['role'], Role.member),
      status: enumByName(
        MemberStatus.values,
        d['status'],
        MemberStatus.pending,
      ),
      departmentIds: List<String>.from(d['departmentIds'] as List? ?? const []),
      createdAt: toDate(d['createdAt']),
    );
  }
}
