import 'package:flutter/material.dart';

/// 바텀시트 대신 쓰는 가운데 대화상자. 모든 대화상자 · 팝업이 이 틀(같은 모서리 · 여백 · 제목 · 버튼 줄)을 쓴다.
Future<T?> showAppDialog<T>(
  BuildContext context, {
  required Widget child,
  double maxWidth = 480,
}) => showDialog<T>(
  context: context,
  builder: (_) => Dialog(
    insetPadding: const EdgeInsets.all(16),
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: child,
      ),
    ),
  ),
);

/// 대화상자의 제목: 왼쪽 정렬, 아래에 일정한 간격.
class DialogTitle extends StatelessWidget {
  const DialogTitle(this.text, {super.key, this.gap = 16});

  final String text;
  final double gap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: gap),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );
}

/// 대화상자 맨 아래의 버튼 줄: 오른쪽 정렬, 버튼 사이 8.
/// 취소 · 닫기는 글자 버튼, 확인 · 저장은 채운 버튼을 쓴다.
class DialogActions extends StatelessWidget {
  const DialogActions({super.key, required this.children, this.top = 24});

  final List<Widget> children;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: top),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          children[i],
        ],
      ],
    ),
  );
}
