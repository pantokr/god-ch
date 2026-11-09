import 'package:flutter/material.dart';

import '../theme.dart';

/// 입력칸 아래 오른쪽에 "현재 / 최대" 글자 수를 보여 주는 `buildCounter`.
/// 한도에 가까워지면(90% 이상) 글자가 붉어진다. 테마는 기본 글자 수 표시를 숨기므로 이 함수를 같이 쓴다.
Widget? charCounter(
  BuildContext context, {
  required int currentLength,
  required bool isFocused,
  required int? maxLength,
}) {
  if (maxLength == null) return null;
  final near = currentLength >= maxLength * 0.9;
  return Text(
    '$currentLength / $maxLength',
    textAlign: TextAlign.right,
    style: TextStyle(
      fontSize: 12.5,
      color: near ? AppColors.like : context.palette.muted,
    ),
  );
}
