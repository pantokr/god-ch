import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_codec.dart';

enum Role { member, staff, admin }

enum MemberStatus { pending, approved, disabled }

/// 한 교회 안에서의 교인 정보. 같은 사람이라도 교회마다 역할·승인 상태가 따로 있다.
class Member {
  const Member({
    required this.id,
    required this.churchId,
    required this.churchName,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.phone = '',
    this.departmentIds = const [],
    this.createdAt,
  });

  /// 사용자(uid)와 같다.
  final String id;
  final String churchId;
  final String churchName;
  final String name;
  final String email;

  /// 가입할 때 받은 전화번호 (교회에 제공하는 것에 동의한 정보).
  final String phone;
  final Role role;
  final MemberStatus status;

  /// 내가 소속을 선택한 부서 (선택 사항, 비어 있어도 된다).
  final List<String> departmentIds;
  final DateTime? createdAt;

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
      email: d['email'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
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
