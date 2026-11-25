import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:god_ch/data/models/prayer.dart';

/// 규칙 점검에서 막은 구멍이 되살아나지 않게 `firestore.rules`의 핵심 조건을 확인한다.
void main() {
  final rules = File('firestore.rules')
      .readAsStringSync()
      .replaceAll('\r\n', '\n');

  /// `match /이름/{...}` 블록의 본문 (다음 같은 깊이의 match 전까지가 아니라, 시작부터 [length]자).
  String after(String marker, {int length = 4000}) {
    final i = rules.indexOf(marker);
    expect(i, greaterThanOrEqualTo(0), reason: marker);
    return rules.substring(i, (i + length).clamp(0, rules.length));
  }

  test('교역자는 승인 대기가 아닌 교인(추방 · 탈퇴 · 거절)을 되살리지 못한다', () {
    expect(
      rules,
      contains(
        "(can(churchId, 'member.manage') && resource.data.role == 'member'\n"
        "                && resource.data.status == 'pending'",
      ),
    );
    expect(
      rules,
      isNot(
        contains(
          "resource.data.status != 'approved'\n                && changed().hasOnly(['status', 'approvedAt'])",
        ),
      ),
    );
  });

  test('중보기도 제목은 새 글에서 필수(1~30자)이고 고칠 때도 같은 길이를 지킨다', () {
    expect(Prayer.maxTitle, 30);
    final block = after('match /prayers/{prayerId}', length: 4500);
    // 새 글: 허용 필드에 title이 있고 비어 있을 수 없다.
    expect(block, contains("'authorName', 'title', 'content'"));
    expect(
      block,
      contains(
        'request.resource.data.title.size() > 0 && request.resource.data.title.size() <= 30',
      ),
    );
    // 작성자 수정: title을 바꿀 수 있고, 바꾸면 길이를 확인한다.
    expect(
      block,
      contains(
        "changed().hasOnly(['title', 'content', 'visibility', 'authorHidden', 'updatedAt', 'responseSeenAt'])",
      ),
    );
    expect(block, contains("!changed().hasAny(['title'])"));
  });

  test('기도 응답은 교인만 읽는다 (앱 운영자 제외)', () {
    final block = after('match /responses/{responseId}', length: 600);
    expect(block, contains('allow read: if isActive(churchId)'));
  });

  test('좋아요 · 참여자 · 읽음 목록에는 중복을 넣을 수 없다', () {
    expect(
      after('function onlyMeDiff', length: 600),
      contains('after.toSet().size() == after.size()'),
    );
    expect(
      after('function readByOk', length: 600),
      contains('readBy.toSet().size() == request.resource.data.readBy.size()'),
    );
    // 기도 · 말씀묵상 모두 같은 읽음 검사를 쓴다.
    expect('&& readByOk()'.allMatches(rules).length, 2);
  });

  test('말씀묵상 수정은 본인 글이거나 글 관리 범위가 전체인 사람만 한다', () {
    expect(
      rules,
      contains(
        "resource.data.get('createdBy', '') == request.auth.uid || isAll(churchId, 'devotion.post')",
      ),
    );
  });

  test('인원 관리 권한을 직급으로 받은 교인도 교인 목록을 읽는다', () {
    final block = after('match /members/{memberId}', length: 900);
    expect(
      block,
      contains(
        "allow list: if isManager(churchId) || can(churchId, 'member.manage')",
      ),
    );
    expect(
      after('match /positions/{positionId}', length: 700),
      contains("|| can(churchId, 'member.manage')"),
    );
  });

  test('사람 목록 카드는 본인 이름과 같아야 하고 직급 이름은 본인이 만들 수 없다', () {
    final block = after('match /people/{personId}', length: 3000);
    expect(
      block,
      contains(
        'request.resource.data.name == get(memberPath(churchId)).data.name',
      ),
    );
    expect(
      block,
      contains("request.resource.data.get('positionName', '') == ''"),
    );
  });

  test('일회용 초대 코드는 입장 신청과 같은 묶음에서 사용 표시가 있어야 한다', () {
    expect(rules, contains('function inviteConsumed(code)'));
    expect(rules, contains('&& inviteConsumed(d.inviteCode)'));
    expect(
      rules,
      contains("getAfter(path).data.get('usedBy', '') == request.auth.uid"),
    );
  });

  test('댓글 · 좋아요 알림은 앱이 쓰는 문구 틀만 허용한다', () {
    final block = after("type in ['postComment', 'postLike']", length: 1500);
    expect(block, contains("title.matches('(?s)댓글 · .{0,31}')"));
    expect(block, contains("title.matches('(?s)좋아요 · .{0,31}')"));
    expect(block, contains('님이 댓글을 남겼어요[.]'));
    expect(block, contains('님이 좋아해요[.]'));
  });

  test('앱이 만드는 알림 문구는 규칙의 틀에 맞는다', () {
    bool full(String pattern, String s) =>
        RegExp('^(?:$pattern)\$', dotAll: true).hasMatch(s);
    // ActivityNotice.add가 만드는 문구와 같은 모양 (제목 30자 + …, 이름 1~100자).
    final long = '가' * 30;
    expect(full('댓글 · .{0,31}', '댓글 · $long…'), isTrue);
    expect(full('댓글 · .{0,31}', '댓글 · '), isTrue);
    expect(full('좋아요 · .{0,31}', '좋아요 · 요 3:16'), isTrue);
    expect(full('.{1,100}님이 댓글을 남겼어요[.]', '김성도님이 댓글을 남겼어요.'), isTrue);
    expect(full('.{1,100}님이 좋아해요[.]', '누군가님이 좋아해요.'), isTrue);
    // 임의 문구는 거부된다.
    expect(
      full('.{1,100}님이 좋아해요[.]', '지금 http://evil.example 로 로그인하세요'),
      isFalse,
    );
  });

  test('규칙 파일에는 BOM이 없다', () {
    final bytes = File('firestore.rules').readAsBytesSync();
    expect(bytes.take(3).toList(), isNot([0xEF, 0xBB, 0xBF]));
  });
}
