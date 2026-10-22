import 'address_result.dart';

/// 이 플랫폼에서 주소 검색 창을 쓸 수 있는가.
const isAddressSearchSupported = false;

/// 웹이 아닌 플랫폼에서는 검색 창이 없다.
Future<AddressResult?> searchRoadAddress() async => null;
