import 'package:flutter/material.dart';

import '../layout/app_dialog.dart';

/// 댓글 수정 창: 지금 내용을 고쳐 저장하면 새 내용을 돌려준다. 취소하거나 바뀐 것이 없으면 null.
Future<String?> showEditComment(
  BuildContext context, {
  required String initial,
  required int maxLength,
}) => showAppDialog<String>(
  context,
  maxWidth: 480,
  child: _EditForm(initial: initial, maxLength: maxLength),
);

class _EditForm extends StatefulWidget {
  const _EditForm({required this.initial, required this.maxLength});

  final String initial;
  final int maxLength;

  @override
  State<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends State<_EditForm> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final text = _controller.text.trim();
        // 비었거나 그대로면 저장할 수 없다.
        final canSave = text.isNotEmpty && text != widget.initial.trim();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('댓글 수정', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              minLines: 3,
              maxLines: 8,
              maxLength: widget.maxLength,
              decoration: const InputDecoration(),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: canSave
                      ? () => Navigator.pop(context, text)
                      : null,
                  child: const Text('저장'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
