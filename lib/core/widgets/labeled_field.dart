import 'package:flutter/material.dart';

import '../theme.dart';
import 'required_label.dart';

/// 이 앱의 기본 입력 한 칸: 이름표는 왼쪽에, 입력칸은 오른쪽에 놓인다.
/// 테두리 안에 떠 있는 이름표(`labelText`)는 쓰지 않는다. 안의 [child]에는 힌트(`hintText`)만 둔다.
/// 여러 줄 입력칸은 [alignTop]으로 이름표를 위쪽에 맞춘다.
/// 놓인 자리가 좁으면(모바일) 입력칸이 너무 좁아지지 않게 이름표가 입력칸 위로 올라간다.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.child,
    this.required = false,
    this.alignTop = false,
    this.stacked = false,
  });

  final String label;
  final bool required;
  final bool alignTop;

  /// 이름표를 입력칸 위에 두고 입력칸이 줄을 바꿔 카드 너비 전체를 차지한다 (긴 글을 쓰는 텍스트 필드는 예외로 이렇게 둔다).
  final bool stacked;
  final Widget child;

  /// 이름표 칸 너비.
  static const labelWidth = 112.0;

  /// 이보다 좁으면 이름표를 입력칸 위로 올린다.
  static const narrow = 340.0;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: context.palette.ink,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.3,
    );
    final text = DefaultTextStyle.merge(
      style: style,
      child: RequiredLabel(label, required: required),
    );
    return LayoutBuilder(
      builder: (context, box) {
        if (stacked || box.maxWidth < narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 6),
                child: text,
              ),
              child,
            ],
          );
        }
        return Row(
          crossAxisAlignment: alignTop
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: labelWidth,
              child: Padding(
                // 위쪽에 맞출 때는 첫 줄의 글자 높이에 맞춘다.
                padding: EdgeInsets.only(right: 12, top: alignTop ? 14 : 0),
                // 이름표가 칸보다 길면 글자를 줄이지 않고 줄을 바꾼다.
                child: text,
              ),
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}
