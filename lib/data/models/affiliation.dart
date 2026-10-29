/// 교회 안의 소속 (예: 청년부). 교역자가 만들고 교인을 넣는다. 교인은 여러 소속에 속할 수 있고,
/// 소속은 교인이 스스로 고를 수 없다.
class Affiliation {
  const Affiliation(this.id, this.name, {this.churchId = ''});

  final String id;
  final String name;

  /// 소속 교회. 모든 교회의 소속을 한 번에 읽는 앱 운영자 화면에서만 채운다.
  final String churchId;
}
