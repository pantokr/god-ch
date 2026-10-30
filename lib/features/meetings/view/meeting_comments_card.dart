import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/widgets/toast.dart';
import '../../../core/widgets/trash_icon.dart';
import '../../../core/format.dart';
import '../../../core/icons.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/comment_composer.dart';
import '../../../data/models/meeting_comment.dart';
import '../../../data/models/member.dart';
import '../../../data/models/permission.dart';
import '../view_model/meeting_comments_view_model.dart';

/// 일정 댓글 카드: 맨 위에 글쓰기 칸과 오른쪽 보내기 아이콘, 그 아래에 최신 댓글부터 목록.
/// 내 댓글은 내가, 남의 댓글은 일정 삭제 권한이 있는 사람이 지운다.
class MeetingCommentsCard extends StatelessWidget {
  const MeetingCommentsCard({
    super.key,
    required this.meetingId,
    required this.me,
  });

  final String meetingId;
  final Member me;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ViewModelBuilder<MeetingCommentsViewModel>(
      key: ValueKey('meeting-comments/$meetingId/${me.id}'),
      create: (context) => MeetingCommentsViewModel(
        AppScope.read(context).meetings,
        me,
        meetingId,
      ),
      builder: (context, vm) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: StreamBuilder<List<MeetingComment>>(
            stream: vm.comments,
            builder: (context, snap) {
              final items = snap.data ?? const <MeetingComment>[];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        AppIcons.messageCircle,
                        size: 18,
                        color: palette.accent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '댓글 ${items.length}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 글쓰기 칸은 맨 위, 댓글은 최신순으로 그 아래에 쌓인다.
                  if (!me.isOperatorView) ...[
                    CommentComposer(
                      hint: '댓글 쓰기',
                      maxLength: MeetingComment.maxLength,
                      busy: vm.busy,
                      onSend: (text) async {
                        final ok = await vm.add(text);
                        if (ok && context.mounted) showAddedToast(context);
                        return ok;
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (snap.hasError)
                    Text('불러오지 못했습니다', style: TextStyle(color: palette.muted))
                  else if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '댓글 없음',
                        style: TextStyle(color: palette.muted),
                      ),
                    ),
                  for (final c in items.reversed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color.alphaBlend(
                            palette.brand.withValues(alpha: 0.05),
                            palette.surface,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppRadius.control,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 10, 8, 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          c.authorName.isEmpty
                                              ? '이름 없음'
                                              : c.authorName,
                                          style: TextStyle(
                                            color: palette.brand,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          fmtDateTime(c.createdAt),
                                          style: TextStyle(
                                            color: palette.muted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(c.text),
                                  ],
                                ),
                              ),
                              if (c.authorId == me.id ||
                                  me.can(Permission.meetingDelete))
                                IconButton(
                                  tooltip: '지우기',
                                  visualDensity: VisualDensity.compact,
                                  icon: const TrashIcon(),
                                  onPressed: vm.busy
                                      ? null
                                      : () => vm.delete(c),
                                ),
                            ],
                          ),
                        ),
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
        ),
      ),
    );
  }
}
