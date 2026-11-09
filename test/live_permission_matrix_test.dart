import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:god_ch/data/models/member.dart';
import 'package:god_ch/data/models/permission.dart';
import 'package:god_ch/data/models/position.dart';

/// 실제 `firestore.rules`가 교인마다 · 권한마다 내린 답(`tool/perm_matrix/perm_matrix.py`가 테스트 교회에서 측정)과
/// 앱의 권한 모델(`Member.can` · `Member.canAll`)이 같은지 맞춰 본다.
/// 측정 결과는 `test/fixtures/permission_matrix.json`에 있다 (시나리오 · 사용자 · 권한별 허용 여부).
///
/// 사용자 번호 (테스트 교회): 1 교회 관리자 · 2 3 교역자 · 5 9 10 14 교인 · 12 추방됨 · 13 소속 없는 교인 · 15 승인 대기.
void main() {
  final file = File('test/fixtures/permission_matrix.json');
  if (!file.existsSync()) {
    test('권한 측정 결과가 없어 건너뜁니다', () {}, skip: true);
    return;
  }
  final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final scenarios = (data['scenarios'] as List).cast<Map<String, dynamic>>();

  Set<String>? keys(Map<String, dynamic>? cfg) =>
      cfg == null ? null : Set<String>.from(cfg['permissions'] as List);
  Map<String, Set<String>>? scopes(Map<String, dynamic>? cfg) => cfg == null
      ? null
      : {
          for (final k in (cfg['mine'] as List? ?? const []))
            k as String: {scopeMine},
        };

  for (final s in scenarios) {
    final name = s['name'] as String;
    final staff = s['staff'] as Map<String, dynamic>?;
    final member = s['member'] as Map<String, dynamic>?;
    final roles = RolePermissions(
      staff: keys(staff),
      member: keys(member),
      staffScopes: scopes(staff),
      memberScopes: scopes(member),
    );
    final members = (s['members'] as Map).cast<String, dynamic>();
    final results = (s['results'] as Map).cast<String, dynamic>();

    group(name, () {
      for (final entry in results.entries) {
        final n = int.parse(entry.key);
        // 13번은 소속이 없어 규칙이 소속 때문에 먼저 막는다 (권한과 무관): 비교에서 뺀다.
        if (n == 13) continue;
        final snap = members[entry.key] as Map<String, dynamic>;
        final m = Member(
          id: 'u$n',
          churchId: 'c',
          churchName: '교회',
          name: '교인$n',
          role: Role.values.byName(snap['role'] as String),
          status: MemberStatus.values.byName(snap['status'] as String),
          permissions: List<String>.from(snap['permissions'] as List),
          permissionScopes: {
            for (final e in (snap['permissionScopes'] as Map).entries)
              e.key as String: Set<String>.from(e.value as List),
          },
          rolePermissions: roles,
        );
        final out = (entry.value as Map).cast<String, dynamic>();
        test('사용자 $n (${snap['role']}, ${snap['status']})', () {
          for (final e in out.entries) {
            if (e.key == 'baseline') continue;
            final p = Permission.values.firstWhere((p) => p.key == e.key);
            final seen = (e.value as Map).cast<String, dynamic>();
            if (seen['can'] != null) {
              expect(
                m.can(p),
                seen['can'],
                reason: '${p.label} 권한(can): 규칙은 ${seen['can']}',
              );
            }
            if (seen['all'] != null) {
              // 규칙이 확인한 "전체 범위" 동작은 모델의 canAll과 같아야 한다.
              // (교회 관리자는 늘 전체다. 관리자가 만든 글을 관리자가 지우는 확인은 본인 글이라 규칙 쪽이 늘 참이다.)
              expect(
                m.canAll(p),
                seen['all'],
                reason: '${p.label} 권한(전체): 규칙은 ${seen['all']}',
              );
            }
          }
        });
      }
    });
  }
}
