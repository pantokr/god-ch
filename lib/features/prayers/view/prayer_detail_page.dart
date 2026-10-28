import '../../../core/icons.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/format.dart';
import '../../../core/layout/sub_page.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/member.dart';
import '../../../data/models/prayer.dart';
import '../view_model/prayer_detail_view_model.dart';
import 'delete_prayer_dialog.dart';
import 'entry_section.dart';
import 'reaction_bar.dart';

/// 주소 `/churches/:cid/prayers/:pid`. 글은 주소의 ID로 불러오므로 링크로 열거나 새로고침해도 된다.
/// 목록에서 들어올 때는 이미 가진 글을 [initial]로 넘겨 바로 보여준다.
class PrayerDetailPage extends StatelessWidget {
  const PrayerDetailPage({
    super.key,
    required this.me,
    required this.prayerId,
    this.initial,
  });

  final Member me;
  final String prayerId;
  final Prayer? initial;

  @override
  Widget build(BuildContext context) {
    final back = Routes.home(me.churchId);
    return ViewModelBuilder<PrayerDetailViewModel>(
      create: (context) =>
          PrayerDetailViewModel(AppScope.read(context).prayers, me, prayerId),
      builder: (context, vm) => StreamBuilder<Prayer?>(
        stream: vm.prayer,
        initialData: initial,
        builder: (context, snap) {
          if (!snap.hasData &&
              !snap.hasError &&
              snap.data == null &&
              snap.connectionState == ConnectionState.waiting) {
            return SubPage(
              title: '기도제목',
              fallbackLocation: back,
              child: const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }
          final p = snap.data;
          if (snap.hasError || vm.isHidden(p)) {
            return SubPage(
              title: '기도제목',
              fallbackLocation: back,
              child: const Card(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: Text('볼 수 없는 기도제목입니다.')),
                ),
              ),
            );
          }
          return SubPage(
            title: p!.title,
            fallbackLocation: back,
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
        icon: const Icon(AppIcons.pencilSimple, size: 18),
        label: const Text('수정'),
        onPressed: () => context.push(Routes.editPrayer(me.churchId, p.id)),
      ),
    if (vm.canDelete(p))
      TextButton.icon(
        icon: const Icon(AppIcons.trash, size: 18),
        label: const Text('삭제'),
        onPressed: () => _confirmDelete(context, vm, p),
      ),
    if (vm.canRestore(p))
      TextButton.icon(
        icon: const Icon(AppIcons.arrowUUpLeft, size: 18),
        label: const Text('복구'),
        onPressed: () => vm.restore(p),
      ),
  ];

  Future<void> _confirmDelete(
    BuildContext context,
    PrayerDetailViewModel vm,
    Prayer p,
  ) async {
    final router = GoRouter.of(context);
    final reason = await showDeletePrayerDialog(
      context,
      needsReason: vm.needsDeleteReason(p),
    );
    if (reason == null) return;
    final ok = await vm.delete(p, reason: reason);
    // 본인 글을 지우면 더 볼 내용이 없으므로 목록으로 돌아간다.
    if (ok && vm.isAuthor(p)) {
      if (router.canPop()) {
        router.pop();
      } else {
        router.go(Routes.home(me.churchId));
      }
    }
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
                // 기도제목 본문은 책처럼 읽히도록 명조로 보여준다.
                SelectableText(p.content, style: readingStyle(context)),
                if (p.isPublic && !p.deleted && vm.settings.reactionsOn) ...[
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
        if (p.isPublic && !p.deleted && vm.settings.staffComments)
          EntrySection(
            title: '교역자 댓글',
            entries: vm.comments,
            canWrite: vm.me.isStaff,
            hint: '교역자 댓글',
            onSend: (text) => vm.addComment(p, text),
            errorOf: () => vm.error,
          ),
        if (!p.isPublic && vm.settings.privateResponses)
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
    final muted = TextStyle(color: context.palette.muted);
    return Row(
      children: [
        Text(fmtDate(prayer.createdAt), style: muted),
        if (prayer.departmentId != null) ...[
          const SizedBox(width: 10),
          Icon(AppIcons.usersThree, size: 14, color: context.palette.muted),
          Text(' 부서 전용', style: muted),
        ],
        if (!prayer.isPublic) ...[
          const SizedBox(width: 10),
          Icon(AppIcons.lock, size: 14, color: context.palette.muted),
          Text(' 교역자 전용', style: muted),
        ],
      ],
    );
  }
}
