import 'package:flutter/material.dart';

import 'confirm_dialog.dart';

/// 작성 중인 내용을 버리고 나가도 되는지 묻는다. 나가면 true.
Future<bool> confirmDiscard(BuildContext context) => confirmChange(
  context,
  title: '작성 취소',
  body: '작성 중인 내용이 사라집니다',
  confirmLabel: '나가기',
  danger: true,
);

/// 작성 화면 보호: 내용이 바뀐 상태([isDirty])에서 뒤로 가기를 누르면 확인을 받는다.
/// 확인하면 [onDiscard] (없으면 화면을 닫는다). [listenable]이 바뀌면 다시 판단한다.
class DiscardGuard extends StatelessWidget {
  const DiscardGuard({
    super.key,
    required this.isDirty,
    required this.child,
    this.listenable,
    this.onDiscard,
  });

  final bool Function() isDirty;
  final Listenable? listenable;
  final VoidCallback? onDiscard;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: listenable ?? Listenable.merge(const []),
      builder: (context, _) => PopScope(
        canPop: !isDirty(),
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          if (!await confirmDiscard(context) || !context.mounted) return;
          if (onDiscard != null) {
            onDiscard!();
          } else {
            Navigator.of(context).pop();
          }
        },
        child: child,
      ),
    );
  }
}
