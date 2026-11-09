import 'package:flutter/material.dart';

import '../icons.dart';
import '../layout/responsive.dart';
import '../theme.dart';

/// 정렬 줄에 놓는 보기 방식 전환 버튼: 테두리 상자 하나에 지금 보기 방식의 아이콘이 있고(리스트형 / 격자형),
/// 누르면 다른 보기 방식으로 바뀌면서 아이콘도 바뀐다. 정렬 선택 상자 왼쪽에 놓는다.
class ViewModeToggle extends StatelessWidget {
  const ViewModeToggle({
    super.key,
    required this.grid,
    required this.onChanged,
  });

  /// 지금 격자형인가.
  final bool grid;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Tooltip(
      message: grid ? '리스트형으로 보기' : '격자형으로 보기',
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.control),
        onTap: () => onChanged(!grid),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: palette.border),
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Icon(
              grid ? AppIcons.gridView : AppIcons.listView,
              size: 20,
              color: palette.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// 카드를 2열로 늘어놓는다. 한 줄의 두 카드는 높이가 같다. 좌우는 목록과 같은 글 여백을 둔다.
class TwoColumn extends StatelessWidget {
  const TwoColumn({super.key, required this.children, this.gap = 12});

  final List<Widget> children;
  final double gap;

  /// 격자 카드의 최소 비율: 가로 3 : 세로 4 (4:3 세로형). 카드는 이보다 납작해지지 않는다.
  static const minHeightPerWidth = 4 / 3;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final gutter = textGutter(context);
        final cols = columnsFor(box.maxWidth);
        final width = (box.maxWidth - gutter * 2 - gap * (cols - 1)) / cols;
        return _build(context, gutter, width * minHeightPerWidth, cols);
      },
    );
  }

  /// 한 행의 카드 수: 좁으면 2개, 넓은 화면은 4개.
  static int columnsFor(double width) => width >= 640 ? 4 : 2;

  Widget _build(
    BuildContext context,
    double gutter,
    double minHeight,
    int cols,
  ) {
    Widget tall(Widget c) => ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: c,
    );
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += cols) {
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: gap),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var k = 0; k < cols; k++) ...[
                  if (k > 0) SizedBox(width: gap),
                  Expanded(
                    child: i + k < children.length
                        ? tall(children[i + k])
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rows,
      ),
    );
  }
}
