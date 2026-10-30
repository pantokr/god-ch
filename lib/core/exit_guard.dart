import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'widgets/exit_ad_slot.dart';

/// 첫 화면(더 돌아갈 곳이 없는 화면)에서 뒤로 가기를 누르면 바로 앱이 닫히지 않고,
/// 앱을 종료할지 먼저 묻는다. 다른 화면 위에 쌓인 화면에서는 평소처럼 이전 화면으로 돌아간다.
/// 묻는 창에는 크기가 고정된 광고 자리가 있다 ([ExitAdSlot]).
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
        final exit = await showDialog<bool>(
          context: context,
          builder: (_) => const _ExitDialog(),
        );
        if (exit == true) await SystemNavigator.pop();
      },
      child: child,
    );
  }
}

/// 앱 종료 확인 창: 제목, 크기가 고정된 광고 자리, 취소 · 종료 버튼.
/// 광고 자리가 고정이라 광고가 늦게 오거나 오지 않아도 창이 커지거나 줄어들지 않는다.
class _ExitDialog extends StatelessWidget {
  const _ExitDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      // 좁은 폰에서도 300px 광고가 들어가도록 바깥 · 안쪽 여백을 줄인다.
      insetPadding: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('앱을 종료할까요?', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            const Center(child: ExitAdSlot()),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('취소'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('종료'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
