import 'package:flutter_test/flutter_test.dart';
import 'package:god_ch/data/models/member.dart';
import 'package:god_ch/data/models/permission.dart';
import 'package:god_ch/data/models/position.dart';

Member _member({
  List<String> permissions = const [],
  Map<String, Set<String>> scopes = const {},
  Role role = Role.staff,
  RolePermissions roles = RolePermissions.defaults,
}) => Member(
  id: 'u',
  churchId: 'c',
  churchName: '교회',
  name: '이름',
  role: role,
  status: MemberStatus.approved,
  permissions: permissions,
  permissionScopes: scopes,
  rolePermissions: roles,
);

void main() {
  test('범위가 없으면 전체다: 타인의 글까지 다룬다', () {
    final m = _member(permissions: ['prayer.post']);
    expect(m.can(Permission.prayerPost), isTrue);
    expect(m.canAll(Permission.prayerPost), isTrue);
  });

  test('본인만이면 권한은 있어도 타인의 것은 다루지 못한다', () {
    final m = _member(
      permissions: ['prayer.post'],
      scopes: {
        'prayer.post': {scopeMine},
      },
    );
    expect(m.can(Permission.prayerPost), isTrue);
    expect(m.canAll(Permission.prayerPost), isFalse);
  });

  test('권한이 없으면 쓸 수 없고, 교회 관리자는 늘 전체다', () {
    final none = _member(role: Role.member);
    expect(none.canAll(Permission.meetingManage), isFalse);
    final admin = _member(role: Role.admin);
    expect(admin.canAll(Permission.meetingManage), isTrue);
    expect(admin.canAll(Permission.prayerPrivate), isTrue);
  });

  test('정한 적이 없는 교인 기본: 글 · 반응 · 댓글 관리는 본인만, 비공개 글 조회는 없다', () {
    final m = _member(role: Role.member);
    expect(m.can(Permission.prayerPost), isTrue);
    expect(m.canAll(Permission.prayerPost), isFalse);
    expect(m.can(Permission.prayerEngage), isTrue);
    expect(m.canAll(Permission.prayerEngage), isFalse);
    expect(m.can(Permission.prayerPrivate), isFalse);
    expect(m.can(Permission.meetingJoin), isTrue);
  });

  test('교역자 기본 권한은 모두 전체다', () {
    final m = _member();
    expect(m.canAll(Permission.prayerPost), isTrue);
    expect(m.canAll(Permission.prayerPrivate), isTrue);
    expect(m.canAll(Permission.meetingParticipants), isTrue);
  });

  test('기본 직급에 정한 범위도 따른다', () {
    final m = _member(
      roles: const RolePermissions(
        staffScopes: {
          'devotion.engage': {scopeMine},
        },
      ),
    );
    expect(m.can(Permission.devotionEngage), isTrue);
    expect(m.canAll(Permission.devotionEngage), isFalse);
    expect(m.canAll(Permission.devotionPost), isTrue);
  });
}
