import 'package:flutter/material.dart';

import '../../people/view/person_popup.dart';

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

/// 말씀 한 편의 댓글: 맨 위 카드에 댓글 수와 글쓰기 칸(오른쪽 보내기 아이콘), 그 아래에 댓글마다 카드 하나씩 최신 댓글부터 이어진다.
/// 새 댓글은 글쓰기 카드 바로 아래에 카드로 붙는다.
/// 한 사람이 여러 댓글을 달 수 있다. 지우기는 댓글마다 있는 휴지통이다
/// (본인 댓글은 누구나, 남의 댓글은 타인 댓글 삭제 권한).
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
      builder: (context, vm) => StreamBuilder<List<DevotionReflection>>(
        stream: vm.reflections,
        builder: (context, snap) {
          final items = snap.data ?? const <DevotionReflection>[];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
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
                      if (canWrite && !me.isOperatorView) ...[
                        const SizedBox(height: 12),
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
                      if (snap.hasError) ...[
                        const SizedBox(height: 12),
                        Text(
                          '불러오지 못했습니다',
                          style: TextStyle(color: palette.muted),
                        ),
                      ] else if (items.isEmpty) ...[
                        const SizedBox(height: 12),
                        Text('댓글 없음', style: TextStyle(color: palette.muted)),
                      ],
                    ],
                  ),
                ),
              ),
              // 댓글 하나에 카드 하나. 새 댓글은 맨 위(글쓰기 카드 바로 아래)에 카드로 붙는다.
              for (final r in items.reversed)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: _Comment(
                    churchId: me.churchId,
                    reflection: r,
                    canDelete:
                        r.authorId == me.id ||
                        me.can(Permission.devotionCommentDeleteOthers),
                    busy: vm.busy,
                    onDelete: () => vm.delete(r.id),
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

/// 댓글 한 건의 카드: 쓴 사람, 시각, 내용, 오른쪽의 휴지통(지울 수 있을 때만).
class _Comment extends StatelessWidget {
  const _Comment({
    required this.churchId,
    required this.reflection,
    required this.canDelete,
    required this.busy,
    required this.onDelete,
  });

  final String churchId;
  final DevotionReflection reflection;
  final bool canDelete;
  final bool busy;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final r = reflection;
    return Card(
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
                  Row(
                    children: [
                      PersonTap(
                        churchId: churchId,
                        uid: r.authorId,
                        name: r.authorName,
                        child: Text(
                          r.authorName.isEmpty ? '이름 없음' : r.authorName,
                          style: TextStyle(
                            color: palette.brand,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
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
    );
  }
}
