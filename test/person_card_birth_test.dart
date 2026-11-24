import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:god_ch/data/models/member.dart';
import 'package:god_ch/data/models/person_card.dart';

PersonCard _card({bool birthPublic = true}) => PersonCard(
  id: 'p',
  name: '김성도',
  role: Role.member,
  status: MemberStatus.approved,
  birthMonthDay: '03-14',
  birthPublic: birthPublic,
);

void main() {
  group('생일 공개', () {
    test('공개이면 누구에게나 보인다', () {
      expect(_card().birthShownTo('other', privileged: false), isTrue);
    });

    test('비공개이면 본인과 교역자 이상에게만 보인다', () {
      final c = _card(birthPublic: false);
      expect(c.birthShownTo('other', privileged: false), isFalse);
      expect(c.birthShownTo('p', privileged: false), isTrue);
      expect(c.birthShownTo('other', privileged: true), isTrue);
    });
  });

  test('규칙이 사람 카드의 birthPublic을 불리언으로만 받는다', () {
    final rules = File('firestore.rules').readAsStringSync();
    expect(rules, contains("'birthPublic', 'updatedAt'"));
    expect(
      rules,
      contains("request.resource.data.get('birthPublic', true) is bool"),
    );
  });
}
