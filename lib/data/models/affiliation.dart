import 'member.dart';

/// 교회 안의 소속 (예: 청년부). 교역자가 만들고 교인을 넣는다. 교인은 여러 소속에 속할 수 있고,
/// 소속은 교인이 스스로 고를 수 없다.
class Affiliation {
  const Affiliation(this.id, this.name, {this.churchId = ''});

  final String id;
  final String name;

  /// 소속 교회. 모든 교회의 소속을 한 번에 읽는 앱 운영자 화면에서만 채운다.
  final String churchId;
}

/// 교인이 소속 분류 줄에서 볼 수 있는 소속.
/// 교회 관리자(와 교회를 보는 앱 개발자)는 모든 소속을, 그 밖의 교인은 자기가 속한 소속만 본다.
/// 소속이 하나도 없는 교인은 아무것도 보지 못한다.
extension MemberAffiliations on Member {
  bool sees(Affiliation a) =>
      isAdmin || isOperatorView || affiliationIds.contains(a.id);

  List<Affiliation> visibleAffiliations(List<Affiliation> all) => [
    for (final a in all)
      if (sees(a)) a,
  ];
}
