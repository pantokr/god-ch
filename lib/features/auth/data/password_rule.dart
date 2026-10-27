/// 비밀번호 규칙. 회원가입과 비밀번호 변경이 같은 규칙으로 검사한다.
class PasswordRule {
  PasswordRule._();

  static const minLength = 8;

  /// 규칙에 맞으면 null, 아니면 보여줄 메시지.
  static String? validate(String? v) =>
      (v == null || v.length < minLength) ? '$minLength자 이상 입력해 주세요' : null;

  /// 확인 칸 검사: [password]와 같아야 한다.
  static String? confirm(String? v, String password) =>
      v != password ? '비밀번호가 일치하지 않아요' : null;
}
