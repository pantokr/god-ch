import 'package:flutter/material.dart';

/// 화면 아래에 잠깐 떴다 사라지는 알림(토스트). 먼저 떠 있던 알림은 바로 걷고 새로 띄운다.
/// 하단 탭 위로 올라오도록 [context]의 아래 여백(떠 있는 탭이 가린 높이)을 더해 띄운다.
void showToast(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  showToastOn(messenger, message, bottom: MediaQuery.paddingOf(context).bottom);
}

/// 화면이 닫힌 뒤에도 쓸 수 있게 미리 잡아 둔 [ScaffoldMessengerState]로 띄우는 토스트.
void showToastOn(
  ScaffoldMessengerState messenger,
  String message, {
  double bottom = 0,
}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(24, 0, 24, 16 + bottom),
        duration: const Duration(milliseconds: 1800),
      ),
    );
}

/// 댓글이나 글을 더한 뒤 띄우는 알림: "추가되었습니다".
void showAddedToast(BuildContext context) => showToast(context, '추가되었습니다');
