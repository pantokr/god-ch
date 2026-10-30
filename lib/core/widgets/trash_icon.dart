import 'package:flutter/material.dart';

import '../icons.dart';

/// 휴지통(삭제) 아이콘: 어디서나 붉은색으로 보인다. 다크 모드에서는 어두운 바탕에서 읽히도록 조금 밝은 붉은색이다.
class TrashIcon extends StatelessWidget {
  const TrashIcon({super.key, this.size = 18});

  final double size;

  /// 라이트 · 다크의 삭제 붉은색.
  static Color colorOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFFF6B6B)
      : const Color(0xFFD7261E);

  /// 삭제 글자 버튼의 모양: 글자와 눌림 효과가 붉은색.
  static ButtonStyle textStyle(BuildContext context) =>
      TextButton.styleFrom(foregroundColor: colorOf(context));

  /// 삭제 확인 버튼의 모양: 붉은 면에 흰 글자.
  static ButtonStyle filledStyle(BuildContext context) =>
      FilledButton.styleFrom(
        backgroundColor: colorOf(context),
        foregroundColor: Colors.white,
      );

  @override
  Widget build(BuildContext context) =>
      Icon(AppIcons.trash, size: size, color: colorOf(context));
}
