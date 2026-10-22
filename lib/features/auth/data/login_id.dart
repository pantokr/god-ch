/// 로그인 ID 규칙. firestore.rules의 loginIds 규칙과 같아야 한다.
class LoginId {
  LoginId._();

  /// 일반 회원은 쓸 수 없는 예약 ID. 앱 운영자 계정 등에 쓴다.
  static const reserved = {
    'admin',
    'administrator',
    'root',
    'system',
    'operator',
  };

  /// 예약 ID 계정의 가상 이메일 도메인. 실제로 메일을 받을 수 없는 주소다.
  static const aliasDomain = 'id.being-built-together.local';

  static final _pattern = RegExp(r'^[a-z][a-z0-9_]{3,19}$');

  /// 공백을 지우고 소문자로 맞춘다 (ID는 대소문자를 구분하지 않는다).
  static String normalize(String input) => input.trim().toLowerCase();

  static bool isReserved(String id) => reserved.contains(id);

  /// 예약 ID 계정의 로그인용 이메일.
  static String aliasEmail(String id) => '$id@$aliasDomain';

  /// 가입할 수 있는 ID인가. 문제가 있으면 안내 문구, 괜찮으면 null.
  static String? validate(String input) {
    final id = normalize(input);
    if (!_pattern.hasMatch(id)) {
      return '영문 소문자로 시작하는 4~20자의 영문 소문자·숫자·_만 쓸 수 있어요';
    }
    if (isReserved(id)) return '사용할 수 없는 ID예요';
    return null;
  }
}
