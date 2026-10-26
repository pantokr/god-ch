import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

extension BackNavigation on BuildContext {
  /// 직전 화면으로 돌아간다. 이전 화면이 없으면(주소로 바로 열었거나 새로고침한 뒤) [fallback]으로 간다.
  void goBack(String fallback) => canPop() ? pop() : go(fallback);
}
