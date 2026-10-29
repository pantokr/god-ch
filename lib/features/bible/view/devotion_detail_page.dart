import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/format.dart';
import '../../../core/icons.dart';
import '../../../core/layout/confirm_dialog.dart';
import '../../../core/layout/sub_page.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/stat_icons.dart';
import '../../../data/models/church_content.dart';
import '../../../data/models/member.dart';
import '../view_model/devotion_detail_view_model.dart';
import 'devotion_form.dart';
import 'reflections_card.dart';

/// 주소 `/churches/:cid/devotion/:id`: 말씀 상세. 말씀 · 묵상 · 반응 · 댓글이 분리된 카드로 보인다.
class DevotionDetailPage extends StatelessWidget {
  const DevotionDetailPage({super.key, required this.me, required this.id});

  final Member me;
  final String id;

  @override
  Widget build(BuildContext context) {
    final back = Routes.section(me.churchId, ChurchSection.bible);
    return ViewModelBuilder<DevotionDetailViewModel>(
      key: ValueKey('devotion/$id'),
      create: (context) => DevotionDetailViewModel(
        AppScope.read(context).contents,
        me.churchId,
        id,
      ),
      builder: (context, vm) => StreamBuilder<ChurchContent?>(
        stream: vm.content,
        builder: (context, snap) {
          final c = snap.data;
          if (c == null) {
            return SubPage(
              title: '말씀',
              fallbackLocation: back,
              child: snap.connectionState == ConnectionState.waiting
                  ? const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : const Card(
                      child: Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(child: Text('볼 수 없는 말씀입니다.')),
                      ),
                    ),
            );
          }
          return SubPage(
            title: c.title,
            fallbackLocation: back,
            actions: [
              if (me.isStaff) ...[
                TextButton.icon(
                  icon: const Icon(AppIcons.pencilSimple, size: 18),
                  label: const Text('수정'),
                  onPressed: () => _edit(context, vm, c),
                ),
                TextButton.icon(
                  icon: const Icon(AppIcons.trash, size: 18),
                  label: const Text('삭제'),
                  onPressed: () => _delete(context, vm, c, back),
                ),
              ],
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _VerseCard(content: c),
                const SizedBox(height: 12),
                _MeditationCard(content: c),
                const SizedBox(height: 12),
                _ReactionCard(content: c, me: me, vm: vm),
                const SizedBox(height: 12),
                ReflectionsCard(devotionId: c.id, me: me),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    DevotionDetailViewModel vm,
    ChurchContent c,
  ) async {
    final result = await showDevotionForm(context, initial: c);
    if (result == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await vm.save(
      title: result.title,
      body: result.body,
      meditation: result.meditation,
      date: result.date,
    );
    if (!ok && vm.error != null) {
      messenger.showSnackBar(SnackBar(content: Text(vm.error!)));
    }
  }

  Future<void> _delete(
    BuildContext context,
    DevotionDetailViewModel vm,
    ChurchContent c,
    String back,
  ) async {
    final router = GoRouter.of(context);
    final ok = await confirmChange(
      context,
      title: '말씀 삭제',
      body: '"${c.title}"을(를) 삭제할까요?',
      confirmLabel: '삭제',
    );
    if (!ok) return;
    if (await vm.delete()) {
      router.canPop() ? router.pop() : router.go(back);
    }
  }
}

/// 카드 한 장의 틀: 이름표 줄과 내용.
class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: palette.accent),
                const SizedBox(width: 8),
                Text(label, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _VerseCard extends StatelessWidget {
  const _VerseCard({required this.content});

  final ChurchContent content;

  @override
  Widget build(BuildContext context) => _Section(
    icon: AppIcons.bookOpen,
    label: '말씀',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(content.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          fmtDate(content.date),
          style: TextStyle(color: context.palette.muted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        SelectableText(content.body, style: readingStyle(context)),
      ],
    ),
  );
}

class _MeditationCard extends StatelessWidget {
  const _MeditationCard({required this.content});

  final ChurchContent content;

  @override
  Widget build(BuildContext context) => _Section(
    icon: AppIcons.sparkles,
    label: '묵상',
    child: content.meditation.isEmpty
        ? Text('묵상 없음', style: TextStyle(color: context.palette.muted))
        : SelectableText(content.meditation, style: readingStyle(context)),
  );
}

/// 반응: 좋아요 버튼과 조회수.
class _ReactionCard extends StatelessWidget {
  const _ReactionCard({
    required this.content,
    required this.me,
    required this.vm,
  });

  final ChurchContent content;
  final Member me;
  final DevotionDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    final liked = content.likedBy.contains(me.id);
    final muted = context.palette.muted;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(
          children: [
            TextButton.icon(
              onPressed: () => vm.setLike(!liked),
              icon: Icon(
                liked ? AppIcons.heartFill : AppIcons.heart,
                size: 20,
                color: liked ? const Color(0xFFE5484D) : muted,
              ),
              label: Text('좋아요 ${StatIcons.compact(content.likes)}'),
            ),
            const Spacer(),
            Icon(AppIcons.eyeCount, size: 16, color: muted),
            const SizedBox(width: 4),
            Text(
              '조회 ${StatIcons.compact(content.views)}',
              style: TextStyle(color: muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
