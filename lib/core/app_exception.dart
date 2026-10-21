/// 사용자에게 그대로 보여줄 수 있는 오류 메시지를 담는다.
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}
