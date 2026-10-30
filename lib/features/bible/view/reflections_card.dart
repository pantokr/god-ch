import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/format.dart';
import '../../../core/icons.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/comment_composer.dart';
import '../../../core/widgets/toast.dart';
import '../../../core/widgets/trash_icon.dart';
import '../../../data/models/devotion_reflection.dart';
import '../../../data/models/member.dart';
import '../../../data/models/permission.dart';
import '../../home/view_model/devotion_reflections_view_model.dart';

/// 말씀 한 편의 댓글: 위에 교인들의 댓글이 오래된 순으로 이어지고, 맨 아래에 글쓰기 칸과 오른쪽 보내기 아이콘이 있다.
/// 한 사람이 여러 댓글을 달 수 있고, 새 댓글은 목록 아래에 덧붙는다. 지우기는 댓글마다 있는 휴지통이다
/// (본인 댓글은 본인 댓글 삭제 권한, 남의 댓글은 타인 댓글 삭제 권한).
class ReflectionsCard extends StatelessWidget {
  const ReflectionsCard({
    super.key,
    required this.devotionId,
    required this.me,
    this.publicList = true,
    this.canWrite = true,
  });

  final String devotionId;
  final Member me;

  /// 댓글을 다른 교인에게도 보여 주는가. 아니면 교인은 내 댓글만 본다.
  final bool publicList;

  /// 댓글 허용 설정. 꺼져 있으면 쓰는 칸 없이 남겨진 댓글만 보인다.
  final bool canWrite;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ViewModelBuilder<DevotionReflectionsViewModel>(
      key: ValueKey('$devotionId/${me.id}/$publicList'),
      create: (context) => DevotionReflectionsViewModel(
        AppScope.read(context).reflections,
        me,
        devotionId,
        publicList: publicList,
      ),
      builder: (context, vm) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: StreamBuilder<List<DevotionReflection>>(
            stream: vm.reflections,
            builder: (context, snap) {
              final items = snap.data ?? const <DevotionReflection>[];
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
                  const SizedBox(height: 14),
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
                  for (final r in items)
                    _Comment(
                      reflection: r,
                      canDelete: me.can(
                        r.authorId == me.id
                            ? Permission.devotionCommentDeleteOwn
                            : Permission.devotionCommentDeleteOthers,
                      ),
                      busy: vm.busy,
                      onDelete: () => vm.delete(r.id),
                    ),
                  if (canWrite && !me.isOperatorView) ...[
                    const SizedBox(height: 6),
                    CommentComposer(
                      hint: '댓글 쓰기',
                      maxLength: DevotionReflection.maxLength,
                      busy: vm.busy,
                      onSend: (text) async {
                        final ok = await vm.add(text);
                        if (ok && context.mounted) showAddedToast(context);
                        return ok;
                      },
                    ),
                  ],
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

/// 댓글 한 줄: 쓴 사람, 시각, 내용, 오른쪽의 휴지통(지울 수 있을 때만).
class _Comment extends StatelessWidget {
  const _Comment({
    required this.reflection,
    required this.canDelete,
    required this.busy,
    required this.onDelete,
  });

  final DevotionReflection reflection;
  final bool canDelete;
  final bool busy;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final r = reflection;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            palette.brand.withValues(alpha: 0.05),
            palette.surface,
          ),
          borderRadius: BorderRadius.circular(AppRadius.control),
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
                          r.authorName.isEmpty ? '이름 없음' : r.authorName,
                          style: TextStyle(
                            color: palette.brand,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          fmtDateTime(r.updatedAt),
                          style: TextStyle(color: palette.muted, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(r.text),
                  ],
                ),
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
        ),
      ),
    );
  }
}
