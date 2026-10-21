import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../data/models/text_entry.dart';

/// 교역자 댓글 / 비공개 글 답변 목록과 입력란.
class EntrySection extends StatefulWidget {
  const EntrySection({
    super.key,
    required this.title,
    required this.entries,
    required this.canWrite,
    required this.hint,
    required this.onSend,
    required this.errorOf,
  });

  final String title;
  final Stream<List<TextEntry>> entries;
  final bool canWrite;
  final String hint;

  /// 전송에 성공하면 true를 돌려준다.
  final Future<bool> Function(String text) onSend;

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
            StreamBuilder<List<TextEntry>>(
              stream: widget.entries,
              builder: (context, snap) {
                final items = snap.data ?? const [];
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      '아직 없습니다.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final e in items)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(e.content),
                        subtitle: Text(fmtDate(e.createdAt)),
                      ),
                  ],
                );
              },
            ),
            if (widget.canWrite) ...[
              const SizedBox(height: 8),
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
          ],
        ),
      ),
    );
  }
}
