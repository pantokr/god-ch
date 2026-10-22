/// 도로명 주소 검색으로 고른 주소.
class AddressResult {
  const AddressResult({required this.roadAddress, required this.zonecode});

  /// 도로명 주소 (예: 서울 중구 세종대로 110).
  final String roadAddress;

  /// 우편번호(5자리).
  final String zonecode;
}
