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
    return MediaQuery(
      data: mq.copyWith(
        textScaler: TextScaler.linear(mq.textScaler.scale(1) * size),
      ),
      child: child,
    );
  }
}
