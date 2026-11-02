// 도로명 주소 검색. 웹에서는 카카오(다음) 우편번호 서비스 팝업을 쓰고,
// 그 밖의 플랫폼(안드로이드 등)에서는 같은 서비스를 전체 화면 웹뷰로 띄운다.
export 'address_result.dart';
export 'address_search_mobile.dart'
    if (dart.library.js_interop) 'address_search_web.dart';
