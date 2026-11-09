import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/trash_icon.dart';
import 'app_dialog.dart';

/// 설정을 바꾸기 전에 한 번 더 확인받는 팝업. 실수나 가벼운 선택으로 바뀌지 않게 한다.
/// 확인을 누르면 true, 취소하거나 바깥을 누르면 false. 다른 대화상자와 같은 틀을 쓴다.
Future<bool> confirmChange(
  BuildContext context, {
  required String title,
  String body = '',
  String confirmLabel = '변경',

  /// 삭제처럼 되돌리기 어려운 동작이면 확인 버튼이 붉은색이다.
  bool danger = false,
}) async {
  final ok = await showAppDialog<bool>(
    context,
    maxWidth: 360,
    child: Builder(
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DialogTitle(title, gap: body.isEmpty ? 0 : 12),
          if (body.isNotEmpty)
            Text(body, style: TextStyle(color: context.palette.muted)),
          DialogActions(
            children: [
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
        ],
      ),
    ),
  );
  return ok == true;
}
