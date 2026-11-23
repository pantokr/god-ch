import 'package:flutter_test/flutter_test.dart';
import 'package:god_ch/data/models/affiliation.dart';
import 'package:god_ch/data/models/member.dart';
import 'package:god_ch/data/models/tab_access.dart';

Member _me(List<String> affiliations, {Role role = Role.member}) => Member(
  id: 'me',
  churchId: 'c',
  churchName: '교회',
  name: '나',
  role: role,
  status: MemberStatus.approved,
  affiliationIds: affiliations,
);

void main() {
  // 목록에는 지운 소속이 없다 (AffiliationRepository가 뺀다).
  const alive = [Affiliation('a', '청년부'), Affiliation('b', '장년부')];

  test('속한 소속이 있으면 그 소속이 선택지다', () {
    final access = TabAccess.of(PageFeature.prayer, _me(['b']), alive);
    expect(access.unassigned, isFalse);
    expect(access.options.map((a) => a.id), ['b']);
  });

  test('속한 소속이 전부 지워졌으면 미배정이다', () {
    final access = TabAccess.of(PageFeature.prayer, _me(['gone']), alive);
    expect(access.unassigned, isTrue);
    expect(access.options, isEmpty);
  });

  test('소속이 없는 교인도 미배정이고, 교역자 이상은 막히지 않는다', () {
    expect(TabAccess.of(PageFeature.word, _me([]), alive).unassigned, isTrue);
    final staff = TabAccess.of(
      PageFeature.word,
      _me(['gone'], role: Role.staff),
      alive,
    );
    expect(staff.unassigned, isFalse);
  });
}
