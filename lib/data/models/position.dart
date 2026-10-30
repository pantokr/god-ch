import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_codec.dart';
import 'permission.dart';

/// 기본 직급 세 개: 교회 관리자(총괄) > 교역자 > 회원. 삭제할 수 없다.
/// 각각 역할([Role])과 같고, 교회 관리자는 그 교회에서 모든 권한(절대 권한)을 가진다.
/// 교역자와 회원은 `churches/{id}/positions/staff` · `.../member` 문서에 권한을 따로 정할 수 있다.
enum BuiltInPosition {
  admin('admin', '교회 관리자', '교회 총괄 관리자'),
  staff('staff', '교역자', '교역자'),
  member('member', '회원', '일반 교인');

  const BuiltInPosition(this.id, this.name, this.subtitle);

  /// 저장되는 문서 ID (교역자 · 회원). 교회 관리자는 문서 없이 코드가 모든 권한을 준다.
  final String id;
  final String name;
  final String subtitle;

  /// 문서 ID가 기본 직급인가 (`staff` · `member`).
  static bool isBuiltInId(String id) => id == 'staff' || id == 'member';
}

/// 기본 직급(교역자 · 회원)에 교회가 정해 둔 권한. null이면 정한 적이 없어 기본값을 쓴다
/// (교역자는 직급으로 줄 수 있는 권한 전부, 회원은 없음).
class RolePermissions {
  const RolePermissions({this.staff, this.member});

  static const defaults = RolePermissions();

  final Set<String>? staff;
  final Set<String>? member;

  /// 교역자가 이 권한을 갖는가 (직급으로 줄 수 있는 권한 기준).
  bool staffHas(Permission p) => staff?.contains(p.key) ?? p.staffDefault;

  bool memberHas(Permission p) => member?.contains(p.key) ?? p.memberDefault;

  static Set<String>? _read(DocumentSnapshot<Json>? doc) {
    final d = doc?.data();
    if (d == null || d['permissions'] is! List) return null;
    return Set<String>.from(d['permissions'] as List);
  }

  factory RolePermissions.fromDocs(
    DocumentSnapshot<Json>? staff,
    DocumentSnapshot<Json>? member,
  ) => RolePermissions(staff: _read(staff), member: _read(member));
}

/// 직급: 교회 관리자가 만드는 이름 있는 권한 묶음. 교인에게 하나 줄 수 있다.
/// `churches/{id}/positions/{id}`에 저장되고, 교인에게 주면 권한이 교인 문서의 `permissions`에 복사된다.
/// 지울 때는 지운 것으로 표시만 남기고, 그 직급의 교인은 직급이 없어진다.
class Position {
  const Position({
    required this.id,
    required this.name,
    this.permissions = const {},
  });

  /// 이름 길이 제한 (`firestore.rules`와 같다).
  static const maxName = 20;

  final String id;
  final String name;

  /// 줄 수 있는 권한의 키들 ([Permission.key]).
  final Set<String> permissions;

  /// 알려진 권한 (정해진 순서대로).
  List<Permission> get granted => [
    for (final p in Permission.delegable)
      if (permissions.contains(p.key)) p,
  ];

  factory Position.fromDoc(DocumentSnapshot<Json> doc) {
    final d = doc.data() ?? const {};
    return Position(
      id: doc.id,
      name: d['name'] as String? ?? '',
      permissions: Set<String>.from(d['permissions'] as List? ?? const []),
    );
  }
}
