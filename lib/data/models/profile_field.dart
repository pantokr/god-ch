/// 가입할 때는 선택이고, 교회가 입장 관리에서 입장 시 필수로 요청할 수 있는 회원 정보.
/// [name]은 교회 설정(`churches/{id}/settings/join`의 `requiredFields`)과 `firestore.rules`에 저장되는 값이다.
enum ProfileField {
  address('주소'),
  birthDate('생년월일');

  const ProfileField(this.label);

  final String label;

  static Set<ProfileField> fromNames(Iterable<Object?> names) => {
    for (final f in values)
      if (names.contains(f.name)) f,
  };
}
