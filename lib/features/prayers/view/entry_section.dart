import 'package:flutter/material.dart';

import '../../../core/widgets/toast.dart';
import '../../../core/widgets/trash_icon.dart';
import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../data/models/text_entry.dart';

/// 교역자 댓글 / 비공개 글 답변: 맨 위에 입력란, 그 아래에 최신순 목록.
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

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
            // 글쓰기 칸은 맨 위, 댓글은 최신순으로 그 아래에 쌓인다.
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
                      decoration: InputDecoration(hintText: widget.hint),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: _send, child: const Text('등록')),
                ],
              ),
            ],
            StreamBuilder<List<TextEntry>>(
              stream: widget.entries,
              builder: (context, snap) {
                final items = snap.data ?? const [];
                if (items.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      '아직 없습니다.',
                      style: TextStyle(color: context.palette.muted),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final e in items.reversed)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(e.content),
                        subtitle: Text(fmtDateTime(e.createdAt)),
                        trailing: (widget.canDelete?.call(e) ?? false)
                            ? IconButton(
                                tooltip: '지우기',
                                icon: const TrashIcon(),
                                onPressed: () => widget.onDelete?.call(e),
                              )
                            : null,
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
