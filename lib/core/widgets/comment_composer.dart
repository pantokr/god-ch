import 'app_loader.dart';

import 'package:flutter/material.dart';

import '../icons.dart';
import '../theme.dart';

/// 댓글 작성줄: 글쓰기 칸 오른쪽에 보내기 아이콘 하나가 붙는다 (글자 버튼 없음).
/// 보내기에 성공하면([onSend]가 true) 칸을 비우고 키보드를 내린다. 비어 있거나 보내는 중이면 눌리지 않는다.
class CommentComposer extends StatefulWidget {
  const CommentComposer({
    super.key,
    required this.onSend,
    this.controller,
    this.hint = '댓글 쓰기',
    this.maxLength = 500,
    this.busy = false,
    this.clearOnSend = true,
    this.sendColor,
  });

  /// 보내기. 성공하면 true를 돌려준다.
  final Future<bool> Function(String text) onSend;

  /// 밖에서 글을 채워 두거나 읽을 때 쓴다 (없으면 안에서 만든다).
  final TextEditingController? controller;
  final String hint;
  final int maxLength;
  final bool busy;

  /// 보낸 뒤 칸을 비우는가 (고쳐 쓰는 글은 그대로 둔다).
  final bool clearOnSend;

  /// 보내기 버튼 색. 없으면 앱의 기본 강조색이다.
  final Color? sendColor;

  @override
  State<CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends State<CommentComposer> {
  TextEditingController? _own;
  bool _sending = false;

  TextEditingController get _controller =>
      widget.controller ?? (_own ??= TextEditingController());

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending || widget.busy) return;
    setState(() => _sending = true);
    final ok = await widget.onSend(text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) {
      if (widget.clearOnSend) _controller.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            minLines: 1,
            maxLines: 5,
            maxLength: widget.maxLength,
            buildCounter: (
              _, {
              required currentLength,
              required isFocused,
              maxLength,
            }) => null,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(color: palette.muted, fontSize: 13),
              filled: true,
              fillColor: palette.surface,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final enabled =
                _controller.text.trim().isNotEmpty && !_sending && !widget.busy;
            return IconButton.filled(
              style: widget.sendColor == null
                  ? null
                  : IconButton.styleFrom(backgroundColor: widget.sendColor),
              tooltip: '보내기',
              onPressed: enabled ? _send : null,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: AppLoader(color: Colors.white),
                    )
                  : const Icon(AppIcons.paperPlaneRight, size: 20),
            );
          },
        ),
      ],
    );
  }
}
