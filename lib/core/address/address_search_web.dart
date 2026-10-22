import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../app_exception.dart';
import 'address_result.dart';

/// 이 플랫폼에서 주소 검색 창을 쓸 수 있는가.
const isAddressSearchSupported = true;

@JS('daum.Postcode')
extension type _DaumPostcode._(JSObject _) implements JSObject {
  external _DaumPostcode(JSObject options);

  external void open();
}

/// 카카오(다음) 우편번호 서비스 창을 열고, 사용자가 고른 도로명 주소를 돌려준다.
/// 창을 선택 없이 닫으면 null을 돌려준다.
/// web/index.html에 우편번호 스크립트가 있어야 한다.
Future<AddressResult?> searchRoadAddress() {
  final completer = Completer<AddressResult?>();
  try {
    final options = JSObject()
      ..setProperty(
        'oncomplete'.toJS,
        ((JSObject data) {
          // 사용자가 지번 주소를 골라도 도로명 주소를 함께 받는다.
          String read(String key) =>
              (data.getProperty<JSString?>(key.toJS))?.toDart ?? '';
          final road = read('roadAddress');
          if (!completer.isCompleted) {
            completer.complete(
              AddressResult(
                roadAddress: road.isNotEmpty ? road : read('address'),
                zonecode: read('zonecode'),
              ),
            );
          }
        }).toJS,
      )
      ..setProperty(
        'onclose'.toJS,
        ((JSAny? _) {
          // 선택이 끝난 뒤에도 불리므로, 아직 결과가 없을 때만 취소로 본다.
          if (!completer.isCompleted) completer.complete(null);
        }).toJS,
      );
    _DaumPostcode(options).open();
  } catch (_) {
    // 스크립트를 불러오지 못했거나 팝업이 막힌 경우.
    return Future.error(
      const AppException('주소 검색 창을 열지 못했습니다. 팝업 차단을 해제하고 다시 시도해 주세요.'),
    );
  }
  return completer.future;
}
