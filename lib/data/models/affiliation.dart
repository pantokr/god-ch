import 'member.dart';

/// 교회 안의 소속 (예: 청년부). 교역자가 만들고 교인을 넣는다. 교인은 여러 소속에 속할 수 있고,
/// 소속은 교인이 스스로 고를 수 없다.
class Affiliation {
  const Affiliation(this.id, this.name, {this.churchId = ''});

  final String id;
  final String name;

  /// 소속 교회. 모든 교회의 소속을 한 번에 읽는 앱 운영자 화면에서만 채운다.
  final String churchId;

  /// 기본 소속 "미배정"의 이름. 입장할 때 소속을 고르지 않은 교인이 여기에 있다.
  static const unassignedName = '미배정';

  /// 기본 소속 "미배정": 문서로 저장하지 않고, 소속이 하나도 없는 교인(`affiliationIds`가 빈 교인)을 뜻한다.
  /// 이름을 바꾸거나 지울 수 없고, 소속별 기능 설정도 없다.
  static const unassigned = Affiliation('unassigned', unassignedName);
}

/// 교인이 소속 분류 줄에서 볼 수 있는 소속.
/// 교회 관리자(와 교회를 보는 앱 개발자)는 모든 소속을, 그 밖의 교인은 자기가 속한 소속만 본다.
/// 소속이 하나도 없는 교인은 아무것도 보지 못한다.
extension MemberAffiliations on Member {
  bool sees(Affiliation a) =>
      isAdmin || isOperatorView || affiliationIds.contains(a.id);
}
