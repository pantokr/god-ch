import 'package:flutter_test/flutter_test.dart';
import 'package:god_ch/data/models/affiliation.dart';
import 'package:god_ch/data/models/member.dart';
import 'package:god_ch/data/models/tab_access.dart';

void main() {
  const all = [
    Affiliation('c', '풋살모임'),
    Affiliation('a', '청년회'),
    Affiliation('d', '장년회'),
    Affiliation('b', '묵상모임'),
  ];

  test('소속은 어디서나 이름 가나다순이다', () {
    expect(all.sortedByName().map((a) => a.name), [
      '묵상모임',
      '장년회',
      '청년회',
      '풋살모임',
    ]);
  });

  test('우측 상단 소속 선택지도 같은 순서다 (교역자 · 교인)', () {
    Member who(Role role) => Member(
      id: 'u',
      churchId: 'c',
      churchName: '교회',
      name: '이름',
      role: role,
      status: MemberStatus.approved,
      affiliationIds: const ['c', 'a', 'd', 'b'],
    );
    for (final role in [Role.staff, Role.member]) {
      final names = TabAccess.of(
        PageFeature.prayer,
        who(role),
        all,
      ).options.map((a) => a.name);
      expect(names, ['묵상모임', '장년회', '청년회', '풋살모임'], reason: '$role');
    }
  });
}
