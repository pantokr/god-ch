import 'package:flutter/material.dart';

/// 설정을 바꾸기 전에 한 번 더 확인받는 팝업. 실수나 가벼운 선택으로 바뀌지 않게 한다.
/// 확인을 누르면 true, 취소하거나 바깥을 누르면 false.
Future<bool> confirmChange(
  BuildContext context, {
  required String title,
  String body = '',
  String confirmLabel = '변경',
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: body.isEmpty ? null : Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok == true;
}
