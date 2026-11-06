import 'package:flutter/material.dart';

import '../../../core/widgets/comment_composer.dart';
import '../../../core/widgets/comment_edit_dialog.dart';
import '../../../core/widgets/comment_parts.dart';
import '../../../core/widgets/toast.dart';
import '../../../core/widgets/trash_icon.dart';
import '../../../core/icons.dart';
import '../../../data/models/text_entry.dart';

/// 댓글 / 비공개 글 답변(댓글에는 쓴 사람 이름이 붙는다): 맨 위 카드에 제목과 입력란, 그 아래에 글마다 카드 하나씩 최신 글부터 이어진다.
class EntrySection extends StatefulWidget {
  const EntrySection({
    super.key,
    required this.title,
    required this.churchId,
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

  /// 이름을 눌렀을 때 프로필을 여는 교회.
  final String churchId;
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
  Future<bool> _send(String text) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await widget.onSend(text);
    if (!mounted) return ok;
    if (ok) {
      showAddedToast(context);
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text('전송하지 못했습니다: ${widget.errorOf()}')),
      );
    }
    return ok;
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
    return StreamBuilder<List<TextEntry>>(
      stream: widget.entries,
      builder: (context, snap) {
        // 읽어 온 순서는 오래된 것이 먼저다. 화면에는 최신 글이 위(글쓰기 카드 바로 아래)에 온다.
        final items = snap.data ?? const <TextEntry>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CommentHeaderCard(
              title: '${widget.title} ${items.length}',
              hasError: snap.hasError,
              composer: widget.canWrite
                  ? CommentComposer(
                      hint: widget.hint,
                      maxLength: widget.maxLength,
                      onSend: _send,
                    )
                  : null,
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
                              CommentByline(
                                churchId: widget.churchId,
                                uid: e.authorId,
                                name: e.authorName,
                                time: e.createdAt,
                                edited: e.edited,
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
