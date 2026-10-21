import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/format.dart';
import '../../../core/layout/sub_page.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/member.dart';
import '../../../data/models/prayer.dart';
import '../view_model/prayer_detail_view_model.dart';
import 'delete_prayer_dialog.dart';
import 'entry_section.dart';
import 'prayer_editor_page.dart';
import 'reaction_bar.dart';

class PrayerDetailPage extends StatelessWidget {
  const PrayerDetailPage({super.key, required this.prayer, required this.me});

  final Prayer prayer;
  final Member me;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<PrayerDetailViewModel>(
      create: (context) =>
          PrayerDetailViewModel(AppScope.read(context).prayers, me, prayer),
      builder: (context, vm) => StreamBuilder<Prayer?>(
        stream: vm.prayer,
        initialData: prayer,
        builder: (context, snap) {
          final p = snap.data;
          if (snap.hasError || vm.isHidden(p)) {
            return const SubPage(
              title: '기도제목',
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: Text('볼 수 없는 기도제목입니다.')),
                ),
              ),
            );
          }
          return SubPage(
            title: p!.title,
            actions: _actions(context, vm, p),
            child: _Body(vm: vm, prayer: p),
          );
        },
      ),
    );
  }

  List<Widget> _actions(
    BuildContext context,
    PrayerDetailViewModel vm,
    Prayer p,
  ) => [
    if (vm.canEdit(p))
      TextButton.icon(
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: const Text('수정'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PrayerEditorPage(me: me, prayer: p),
          ),
        ),
      ),
    if (vm.canDelete(p))
      TextButton.icon(
        icon: const Icon(Icons.delete_outline, size: 18),
        label: const Text('삭제'),
        onPressed: () => _confirmDelete(context, vm, p),
      ),
    if (vm.canRestore(p))
      TextButton.icon(
        icon: const Icon(Icons.restore_from_trash, size: 18),
        label: const Text('복구'),
        onPressed: () => vm.restore(p),
      ),
  ];

  Future<void> _confirmDelete(
    BuildContext context,
    PrayerDetailViewModel vm,
    Prayer p,
  ) async {
    final navigator = Navigator.of(context);
    final reason = await showDeletePrayerDialog(
      context,
      needsReason: vm.needsDeleteReason(p),
    );
    if (reason == null) return;
    final ok = await vm.delete(p, reason: reason);
    // 본인 글을 지우면 더 볼 내용이 없으므로 목록으로 돌아간다.
    if (ok && vm.isAuthor(p)) navigator.pop();
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.vm, required this.prayer});

  final PrayerDetailViewModel vm;
  final Prayer prayer;

  @override
  Widget build(BuildContext context) {
    final p = prayer;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                _MetaRow(prayer: p),
                if (p.deleted) ...[
                  const SizedBox(height: 12),
                  Text(
                    '삭제됨 · 사유: ${p.deleteReason ?? '-'}',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: 20),
                SelectableText(
                  p.content,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.7),
                ),
                if (p.isPublic && !p.deleted) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  ReactionBar(churchId: vm.me.churchId, prayerId: p.id),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (p.isPublic && !p.deleted)
          EntrySection(
            title: '교역자 댓글',
            entries: vm.comments,
            canWrite: vm.me.isStaff,
            hint: '교역자 댓글',
            onSend: (text) => vm.addComment(p, text),
            errorOf: () => vm.error,
          ),
        if (!p.isPublic)
          EntrySection(
            title: '교역자 답변',
            entries: vm.responses,
            canWrite: vm.me.isStaff && !p.deleted,
            hint: '답변 작성',
            onSend: (text) => vm.addResponse(p, text),
            errorOf: () => vm.error,
          ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.prayer});

  final Prayer prayer;

  @override
  Widget build(BuildContext context) {
    const muted = TextStyle(color: AppColors.muted);
    return Row(
      children: [
        Text(fmtDate(prayer.createdAt), style: muted),
        if (prayer.departmentId != null) ...[
          const SizedBox(width: 10),
          const Icon(Icons.groups_outlined, size: 14, color: AppColors.muted),
          const Text(' 부서 전용', style: muted),
        ],
        if (!prayer.isPublic) ...[
          const SizedBox(width: 10),
          const Icon(Icons.lock_outline, size: 14, color: AppColors.muted),
          const Text(' 교역자 전용', style: muted),
        ],
      ],
    );
  }
}
