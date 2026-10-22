// 도로명 주소 검색. 웹에서는 카카오(다음) 우편번호 서비스를 쓰고,
// 아직 지원하지 않는 플랫폼에서는 isAddressSearchSupported가 false라 직접 입력으로 대신한다.
export 'address_result.dart';
export 'address_search_stub.dart'
    if (dart.library.js_interop) 'address_search_web.dart';
