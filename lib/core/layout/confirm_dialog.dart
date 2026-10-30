import 'package:flutter/material.dart';

import '../widgets/trash_icon.dart';

/// 설정을 바꾸기 전에 한 번 더 확인받는 팝업. 실수나 가벼운 선택으로 바뀌지 않게 한다.
/// 확인을 누르면 true, 취소하거나 바깥을 누르면 false.
Future<bool> confirmChange(
  BuildContext context, {
  required String title,
  String body = '',
  String confirmLabel = '변경',

  /// 삭제처럼 되돌리기 어려운 동작이면 확인 버튼이 붉은색이다.
  bool danger = false,
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
          style: danger ? TrashIcon.filledStyle(context) : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok == true;
}
