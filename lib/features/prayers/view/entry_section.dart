import 'package:flutter/material.dart';

import '../../../core/widgets/comment_edit_dialog.dart';
import '../../../core/widgets/toast.dart';
import '../../../core/widgets/trash_icon.dart';
import '../../../core/format.dart';
import '../../../core/icons.dart';
import '../../../core/theme.dart';
import '../../../data/models/text_entry.dart';

/// 댓글 / 비공개 글 답변(댓글에는 쓴 사람 이름이 붙는다): 맨 위 카드에 제목과 입력란, 그 아래에 글마다 카드 하나씩 최신 글부터 이어진다.
class EntrySection extends StatefulWidget {
  const EntrySection({
    super.key,
    required this.title,
    required this.entries,
    required this.canWrite,
    required this.hint,
    required this.onSend,
    required this.errorOf,
    this.canDelete,
    this.onDelete,
    this.canEdit,
    this.onEdit,
    this.maxLength = 500,
  });

  final String title;
  final Stream<List<TextEntry>> entries;
  final bool canWrite;
  final String hint;

  /// 전송에 성공하면 true를 돌려준다.
  final Future<bool> Function(String text) onSend;

  /// 이 항목을 지울 수 있는가 (없으면 지우기 버튼이 없다).
  final bool Function(TextEntry entry)? canDelete;
  final Future<bool> Function(TextEntry entry)? onDelete;

  /// 이 항목을 고칠 수 있는가 (없으면 수정 버튼이 없다). 고친 내용 저장에 성공하면 true를 돌려준다.
  final bool Function(TextEntry entry)? canEdit;
  final Future<bool> Function(TextEntry entry, String text)? onEdit;
  final int maxLength;

  /// 마지막 전송 실패 이유.
  final String? Function() errorOf;

  @override
  State<EntrySection> createState() => _EntrySectionState();
}

class _EntrySectionState extends State<EntrySection> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    if (await widget.onSend(text)) {
      _controller.clear();
      if (mounted) showAddedToast(context);
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text('전송하지 못했습니다: ${widget.errorOf()}')),
      );
    }
  }

  Future<void> _edit(TextEntry e) async {
    final messenger = ScaffoldMessenger.of(context);
    final text = await showEditComment(
      context,
      initial: e.content,
      maxLength: widget.maxLength,
    );
    if (text == null) return;
    if (!(await widget.onEdit?.call(e, text) ?? false)) {
      messenger.showSnackBar(
        SnackBar(content: Text('수정하지 못했습니다: ${widget.errorOf()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return StreamBuilder<List<TextEntry>>(
      stream: widget.entries,
      builder: (context, snap) {
        // 읽어 온 순서는 오래된 것이 먼저다. 화면에는 최신 글이 위(글쓰기 카드 바로 아래)에 온다.
        final items = snap.data ?? const <TextEntry>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (widget.canWrite) ...[
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              minLines: 1,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: widget.hint,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: _send,
                            child: const Text('등록'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // 글 하나에 카드 하나.
            for (final e in items.reversed)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                [
                                  if (e.authorName.isNotEmpty) e.authorName,
                                  fmtDateTime(e.createdAt),
                                  if (e.edited) '수정됨',
                                ].join(' · '),
                                style: TextStyle(
                                  color: palette.muted,
                                  fontSize: 12.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(e.content),
                            ],
                          ),
                        ),
                        if (widget.canEdit?.call(e) ?? false)
                          IconButton(
                            tooltip: '수정',
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(AppIcons.pencilSimple, size: 18),
                            onPressed: () => _edit(e),
                          ),
                        if (widget.canDelete?.call(e) ?? false)
                          IconButton(
                            tooltip: '지우기',
                            visualDensity: VisualDensity.compact,
                            icon: const TrashIcon(),
                            onPressed: () => widget.onDelete?.call(e),
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
