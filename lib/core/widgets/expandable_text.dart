import 'package:flutter/material.dart';

import '../icons.dart';
import '../theme.dart';

/// 긴 글을 [maxLines]줄까지만 보이고 "더보기"로 펼치는 글. 넘치지 않는 짧은 글은 그대로 보인다.
/// 펼치면 선택해서 복사할 수 있고 "접기"로 다시 줄인다.
class ExpandableText extends StatefulWidget {
  const ExpandableText(
    this.text, {
    super.key,
    this.style,
    this.maxLines = 8,
    this.onDark = false,
  });

  final String text;
  final TextStyle? style;
  final int maxLines;

  /// 더보기 글자색을 본문색에 맞춘다 (색이 깔린 카드 위).
  final bool onDark;

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _open = false;

  @override
  void didUpdateWidget(ExpandableText old) {
    super.didUpdateWidget(old);
    // 다른 글로 바뀌면 다시 접는다.
    if (old.text != widget.text) _open = false;
  }

  Widget _full(BuildContext context, TextStyle style) =>
      SelectionContainer.maybeOf(context) != null
      ? Text(widget.text, style: style)
      : SelectableText(widget.text, style: style);

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? DefaultTextStyle.of(context).style;
    return LayoutBuilder(
      builder: (context, box) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: widget.maxLines,
        )..layout(maxWidth: box.maxWidth);
        final overflows = painter.didExceedMaxLines;
        painter.dispose();
        final ink = style.color ?? context.palette.ink;
        final more = TextStyle(
          color: ink,
          fontWeight: FontWeight.w600,
          fontSize: 13.5,
          height: 1.2,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_open || !overflows)
              // 글자를 끌어 선택할 수 있는 화면(SelectionArea) 안에서는 그 선택을 따르고, 아니면 스스로 선택된다.
              _full(context, style)
            else
              Text(
                widget.text,
                style: style,
                maxLines: widget.maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            if (overflows)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                // 본문과 한눈에 구별되도록 테두리 있는 버튼 모양에 화살표를 붙인다.
                child: InkWell(
                  onTap: () => setState(() => _open = !_open),
                  borderRadius: BorderRadius.circular(AppRadius.control),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: ink.withValues(alpha: 0.06),
                      border: Border.all(color: ink.withValues(alpha: 0.4)),
                      borderRadius: BorderRadius.circular(AppRadius.control),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_open ? '접기' : '더보기', style: more),
                        const SizedBox(width: 4),
                        Icon(
                          _open ? AppIcons.caretUp : AppIcons.caretDown,
                          size: 16,
                          color: ink,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
