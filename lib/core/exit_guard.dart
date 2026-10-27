import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'layout/confirm_dialog.dart';

/// 첫 화면(더 돌아갈 곳이 없는 화면)에서 뒤로 가기를 누르면 바로 앱이 닫히지 않고,
/// 앱을 종료할지 먼저 묻는다. 다른 화면 위에 쌓인 화면에서는 평소처럼 이전 화면으로 돌아간다.
/// 웹에서는 브라우저가 알아서 하므로 아무것도 하지 않는다.
class ExitGuard extends StatelessWidget {
  const ExitGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return child;
    // 이 화면이 스택의 맨 아래이면 뒤로 가기는 앱 종료를 뜻한다.
    final atRoot = ModalRoute.of(context)?.isFirst ?? false;
    return PopScope(
      canPop: !atRoot,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final exit = await confirmChange(
          context,
          title: '앱을 종료할까요?',
          confirmLabel: '종료',
        );
        if (exit) await SystemNavigator.pop();
      },
      child: child,
    );
  }
}
