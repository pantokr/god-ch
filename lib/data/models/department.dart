/// 교회 안의 부서 (예: 청년부). 소속은 교인이 직접 선택한다.
class Department {
  const Department(this.id, this.name, {this.churchId = ''});

  final String id;
  final String name;

  /// 소속 교회. 모든 교회의 부서를 한 번에 읽는 앱 운영자 화면에서만 채운다.
  final String churchId;
}
