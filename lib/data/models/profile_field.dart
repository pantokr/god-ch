/// 가입할 때는 선택이고, 교회가 초대 코드로 필수 입력을 요청할 수 있는 회원 정보.
/// [name]은 초대 코드(`requiredFields`)와 `firestore.rules`에 저장되는 값이다.
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
