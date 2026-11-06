import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/widgets/comment_edit_dialog.dart';
import '../../../core/widgets/toast.dart';
import '../../../core/widgets/trash_icon.dart';
import '../../../core/icons.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/comment_composer.dart';
import '../../../core/widgets/comment_parts.dart';
import '../../../data/models/meeting_comment.dart';
import '../../../data/models/member.dart';
import '../../../data/models/permission.dart';
import '../view_model/meeting_comments_view_model.dart';

/// 일정 댓글: 맨 위 카드에 댓글 수와 글쓰기 칸, 그 아래에 댓글마다 카드 하나씩 최신 댓글부터 이어진다.
/// 답글(대댓글)은 부모 댓글 아래에 오래된 순으로 붙고, 들여쓰기는 최대 2단이다.
/// 내 댓글은 내가, 남의 댓글은 일정 삭제 권한이 있는 사람이 지운다.
class MeetingCommentsCard extends StatefulWidget {
  const MeetingCommentsCard({
    super.key,
    required this.meetingId,
    required this.me,
    this.canWrite = true,
    this.publicList = true,
  });

  final String meetingId;
  final Member me;

  /// 댓글을 다른 교인에게도 보여 주는가. 아니면 일정 삭제 권한이 없는 교인은 내 댓글만 본다.
  final bool publicList;

  /// 댓글 허용 설정. 꺼져 있으면 쓰는 칸 · 답글 없이 남겨진 댓글만 보인다.
  final bool canWrite;

  @override
  State<MeetingCommentsCard> createState() => _MeetingCommentsCardState();
}

/// 화면에 그려지는 댓글 한 줄: 댓글, 들여쓰기 단계(0~2), 지워졌지만 답글이 있어 자리만 남는지.
class _Node {
  const _Node(this.comment, this.depth, {this.placeholder = false});

  final MeetingComment comment;
  final int depth;
  final bool placeholder;
}

/// 들여쓰기 최대 단계.
const _maxDepth = 2;

/// 댓글들을 화면 순서로 편다: 최상위는 최신순, 각 댓글의 답글은 오래된 순으로 바로 아래에 붙는다.
/// 지운 댓글은 답글이 없으면 빼고, 있으면 "삭제된 댓글" 자리만 남긴다. 부모를 못 찾는 답글은 최상위로 본다.
List<_Node> _flatten(List<MeetingComment> all) {
  final ids = {for (final c in all) c.id};
  final children = <String, List<MeetingComment>>{};
  final roots = <MeetingComment>[];
  for (final c in all) {
    final p = c.parentId;
    if (p != null && ids.contains(p)) {
      children.putIfAbsent(p, () => []).add(c);
    } else {
      roots.add(c);
    }
  }
  // 이 댓글 밑에 지워지지 않은 댓글이 하나라도 있는가.
  bool alive(MeetingComment c) =>
      !c.deleted || (children[c.id] ?? const []).any(alive);

  final out = <_Node>[];
  void walk(MeetingComment c, int depth) {
    if (!alive(c)) return;
    out.add(_Node(c, depth.clamp(0, _maxDepth), placeholder: c.deleted));
    for (final child in children[c.id] ?? const <MeetingComment>[]) {
      walk(child, depth + 1);
    }
  }

  DateTime at(MeetingComment c) => c.createdAt ?? DateTime(9999);
  final newestFirst = [...roots]..sort((a, b) => at(b).compareTo(at(a)));
  for (final r in newestFirst) {
    walk(r, 0);
  }
  return out;
}

class _MeetingCommentsCardState extends State<MeetingCommentsCard> {
  /// 답글을 쓰고 있는 댓글의 id.
  String? _replyTo;

  @override
  Widget build(BuildContext context) {
    final me = widget.me;
    return ViewModelBuilder<MeetingCommentsViewModel>(
      key: ValueKey(
        'meeting-comments/${widget.meetingId}/${me.id}/${widget.publicList}',
      ),
      create: (context) => MeetingCommentsViewModel(
        AppScope.read(context).meetings,
        me,
        widget.meetingId,
        publicList: widget.publicList,
      ),
      builder: (context, vm) => StreamBuilder<List<MeetingComment>>(
        stream: vm.comments,
        builder: (context, snap) {
          final all = snap.data ?? const <MeetingComment>[];
          final count = all.where((c) => !c.deleted).length;
          final nodes = _flatten(all);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CommentHeaderCard(
                title: '댓글 $count',
                hasError: snap.hasError,
                composer: !me.isOperatorView && widget.canWrite
                    ? CommentComposer(
                        hint: '댓글 쓰기',
                        maxLength: MeetingComment.maxLength,
                        busy: vm.busy,
                        onSend: (text) async {
                          final ok = await vm.add(text);
                          if (ok && context.mounted) showAddedToast(context);
                          return ok;
                        },
                      )
                    : null,
              ),
              // 댓글 하나에 카드 하나. 답글은 들여쓰기 단계마다 16씩 안으로 들어간다.
              for (final n in nodes)
                Padding(
                  padding: EdgeInsets.only(left: n.depth * 16.0, top: 10),
                  child: _CommentCard(
                    node: n,
                    me: me,
                    canReply: widget.canWrite,
                    busy: vm.busy,
                    replying: _replyTo == n.comment.id,
                    onReplyToggle: () => setState(
                      () => _replyTo = _replyTo == n.comment.id
                          ? null
                          : n.comment.id,
                    ),
                    onReply: (text) async {
                      // 두 번째 단계 댓글에 다는 답글은 같은 단계의 형제로 붙는다 (최대 2단).
                      final parent = n.depth >= _maxDepth
                          ? (n.comment.parentId ?? n.comment.id)
                          : n.comment.id;
                      final ok = await vm.add(text, parentId: parent);
                      if (ok && mounted) {
                        setState(() => _replyTo = null);
                        if (context.mounted) showAddedToast(context);
                      }
                      return ok;
                    },
                    canEdit:
                        widget.canWrite &&
                        !me.isOperatorView &&
                        n.comment.authorId == me.id,
                    onEdit: () async {
                      final text = await showEditComment(
                        context,
                        initial: n.comment.text,
                        maxLength: MeetingComment.maxLength,
                      );
                      if (text != null) await vm.edit(n.comment, text);
                    },
                    onDelete: () => vm.delete(n.comment),
                  ),
                ),
              if (vm.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    vm.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// 댓글 한 건의 카드: 이름과 작성 시각, 내용, 아래에 답글 · 지우기. 지워진 댓글은 자리만 남는다.
class _CommentCard extends StatelessWidget {
  const _CommentCard({
    required this.node,
    required this.me,
    required this.canReply,
    required this.busy,
    required this.replying,
    required this.onReplyToggle,
    required this.onReply,
    required this.onDelete,
    required this.canEdit,
    required this.onEdit,
  });

  final _Node node;
  final Member me;
  final bool canReply;
  final bool busy;
  final bool replying;
  final VoidCallback onReplyToggle;
  final Future<bool> Function(String text) onReply;
  final VoidCallback onDelete;
  final bool canEdit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final c = node.comment;
    if (node.placeholder) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('삭제된 댓글', style: TextStyle(color: palette.muted)),
        ),
      );
    }
    final canDelete = c.authorId == me.id || me.can(Permission.meetingDelete);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CommentByline(
                churchId: me.churchId,
                uid: c.authorId,
                name: c.authorName,
                time: c.createdAt,
                edited: c.editedAt != null,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(c.text),
            ),
            Row(
              children: [
                if (!me.isOperatorView && canReply)
                  TextButton(
                    onPressed: onReplyToggle,
                    style: TextButton.styleFrom(
                      foregroundColor: palette.muted,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                    child: Text(replying ? '답글 취소' : '답글'),
                  ),
                const Spacer(),
                if (canEdit)
                  IconButton(
                    tooltip: '수정',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(AppIcons.pencilSimple, size: 18),
                    onPressed: busy ? null : onEdit,
                  ),
                if (canDelete)
                  IconButton(
                    tooltip: '지우기',
                    visualDensity: VisualDensity.compact,
                    icon: const TrashIcon(),
                    onPressed: busy ? null : onDelete,
                  ),
              ],
            ),
            if (replying)
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 8),
                child: CommentComposer(
                  hint: '답글 쓰기',
                  maxLength: MeetingComment.maxLength,
                  busy: busy,
                  onSend: onReply,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
