import 'package:flutter/material.dart';

import '../app/app_scope.dart';

/// 화면 하나의 글씨 크기를 개인 설정에 맞춘다: 안쪽 글자 배율을 더 곱한다.
/// 글꼴은 바꾸지 않는다 (명조는 말씀 본문 카드에만 쓴다).
class ScreenStyle extends StatelessWidget {
  const ScreenStyle({super.key, required this.screen, required this.child});

  final String screen;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = AppScope.read(context).preferences.sizeOf(screen).factor;
    if (size == 1.0) return child;
    final mq = MediaQuery.of(context);
    return _ScreenSizeScope(
      factor: size,
      child: MediaQuery(
        data: mq.copyWith(
          textScaler: TextScaler.linear(mq.textScaler.scale(1) * size),
        ),
        child: child,
      ),
    );
  }

  /// 이 화면에만 더해진 글씨 크기 배율 (없으면 1). 화면 설정과 상관없이 같은 크기여야 하는 요소
  /// (예: 떠 있는 새 글 버튼)가 [unscaled]로 되돌릴 때 쓴다.
  static double factorOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ScreenSizeScope>()?.factor ??
      1.0;

  /// 화면별 글씨 크기를 되돌려, 앱 전체 글씨 크기만 따르게 감싼다.
  static Widget unscaled(BuildContext context, Widget child) {
    final factor = factorOf(context);
    if (factor == 1.0) return child;
    final mq = MediaQuery.of(context);
    return MediaQuery(
      data: mq.copyWith(
        textScaler: TextScaler.linear(mq.textScaler.scale(1) / factor),
      ),
      child: child,
    );
  }
}

class _ScreenSizeScope extends InheritedWidget {
  const _ScreenSizeScope({required this.factor, required super.child});

  final double factor;

  @override
  bool updateShouldNotify(_ScreenSizeScope old) => old.factor != factor;
}
