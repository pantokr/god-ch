import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/format.dart';
import '../../../core/layout/app_dialog.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/member.dart';
import '../../../data/models/prayer.dart';
import '../../home/view/content_widgets.dart';
import '../../prayers/view/delete_prayer_dialog.dart';
import '../view_model/post_manage_view_model.dart';

/// 게시글 관리: 회원이 쓸 수 있는 곳(지금은 메신저·중보기도 요청)의 글을 모아 보고,
/// 유해하거나 고쳐야 하는 글은 수정·삭제한다. 삭제한 글은 "삭제됨"에서 복구할 수 있다.
/// 비공개(교역자 전용) 글은 내용을 목록에 펼치지 않는다 — "자세히"로 열면 열람 기록이 남는다.
class PostManagePage extends StatelessWidget {
  const PostManagePage({super.key, required this.me});

  final Member me;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<PostManageViewModel>(
      create: (context) {
        final scope = AppScope.read(context);
        return PostManageViewModel(
          scope.prayers,
          scope.members,
          scope.departments,
          me.churchId,
        );
      },
      builder: (context, vm) => SingleChildScrollView(
        child: PageFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageTitle(
                title: '게시글 관리',
                subtitle: '회원이 쓴 글을 확인하고, 고치거나 지워요.',
              ),
              // 회원이 글을 쓸 수 있는 곳. 선택한 곳의 글만 아래에 나열된다.
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in PostSource.values)
                    ChoiceChip(
                      label: Text(s.label),
                      selected: vm.source == s,
                      onSelected: (_) => vm.setSource(s),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                vm.source.description,
                style: TextStyle(color: context.palette.muted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: vm.setQuery,
                decoration: const InputDecoration(
                  hintText: '제목이나 작성자로 찾기',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<PostFilter>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: PostFilter.all, label: Text('전체')),
                    ButtonSegment(
                      value: PostFilter.private,
                      label: Text('교역자 전용'),
                    ),
                    ButtonSegment(
                      value: PostFilter.deleted,
                      label: Text('삭제됨'),
                    ),
                  ],
                  selected: {vm.filter},
                  onSelectionChanged: (s) => vm.setFilter(s.first),
                ),
              ),
              if (vm.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    vm.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _PostList(me: me, vm: vm),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostList extends StatelessWidget {
  const _PostList({required this.me, required this.vm});

  final Member me;
  final PostManageViewModel vm;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, String>>(
      stream: vm.authorNames,
      builder: (context, names) => StreamBuilder<Map<String, String>>(
        stream: vm.departmentNames,
        builder: (context, depts) => StreamBuilder<List<Prayer>>(
          stream: vm.allPrayers,
          builder: (context, snap) {
            if (snap.hasError) return Text('불러오지 못했습니다\n${snap.error}');
            final all = snap.data;
            if (all == null) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final authors = names.data ?? const <String, String>{};
            final shown = all.where((p) => vm.matches(p, authors)).toList();
            if (shown.isEmpty) return const EmptyHint('해당하는 글이 없어요.');
            return Column(
              children: [
                for (final p in shown)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PostCard(
                      prayer: p,
                      me: me,
                      vm: vm,
                      author: authors[p.authorId] ?? '알 수 없음',
                      department: depts.data?[p.departmentId],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.prayer,
    required this.me,
    required this.vm,
    required this.author,
    this.department,
  });

  final Prayer prayer;
  final Member me;
  final PostManageViewModel vm;
  final String author;
  final String? department;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final muted = TextStyle(color: palette.muted, fontSize: 13);
    final p = prayer;
    // 비공개 글은 내용을 펼치지 않는다.
    final showContent = p.isPublic;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  author,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(fmtDate(p.createdAt), style: muted),
                if (!p.isPublic) const _Badge('교역자 전용'),
                if (department != null) _Badge(department!),
                if (p.deleted) const _Badge('삭제됨', warn: true),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              p.title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 4),
            if (showContent)
              Text(p.content, maxLines: 4, overflow: TextOverflow.ellipsis)
            else
              Text('비공개 글이라 내용은 "자세히"에서 확인해요.', style: muted),
            if (p.deleted && (p.deleteReason ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('삭제 사유: ${p.deleteReason}', style: muted),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () =>
                      context.push(Routes.prayer(me.churchId, p.id), extra: p),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('자세히'),
                ),
                // 공개 글만 고칠 수 있다 (비공개 글은 삭제만).
                if (!p.deleted && p.isPublic)
                  OutlinedButton.icon(
                    onPressed: vm.busy ? null : () => _edit(context),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('수정'),
                  ),
                if (!p.deleted)
                  OutlinedButton.icon(
                    onPressed: vm.busy ? null : () => _delete(context),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('삭제'),
                  )
                else
                  FilledButton.icon(
                    onPressed: vm.busy ? null : () => vm.restore(p.id),
                    icon: const Icon(Icons.restore, size: 16),
                    label: const Text('복구'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final result = await showAppDialog<({String title, String content})>(
      context,
      maxWidth: 560,
      child: _EditForm(prayer: prayer),
    );
    if (result == null) return;
    await vm.edit(prayer.id, title: result.title, content: result.content);
  }

  Future<void> _delete(BuildContext context) async {
    final reason = await showDeletePrayerDialog(context, needsReason: true);
    if (reason == null) return;
    await vm.delete(prayer.id, reason);
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, {this.warn = false});

  final String text;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final color = warn
        ? Theme.of(context).colorScheme.error
        : context.palette.brand;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// 글의 제목·내용을 고치는 대화상자. 저장하면 고친 값을 돌려준다.
class _EditForm extends StatefulWidget {
  const _EditForm({required this.prayer});

  final Prayer prayer;

  @override
  State<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends State<_EditForm> {
  late final _title = TextEditingController(text: widget.prayer.title);
  late final _content = TextEditingController(text: widget.prayer.content);

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('글 수정', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          '유해하거나 고쳐야 하는 내용만 고쳐 주세요. 고친 사람과 시각이 기록돼요.',
          style: TextStyle(color: context.palette.muted, fontSize: 13),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _title,
          maxLength: 100,
          decoration: const InputDecoration(labelText: '제목'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _content,
          minLines: 5,
          maxLines: 12,
          maxLength: 3000,
          decoration: const InputDecoration(
            labelText: '내용',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => Navigator.pop(context, (
                title: _title.text,
                content: _content.text,
              )),
              child: const Text('저장'),
            ),
          ],
        ),
      ],
    );
  }
}
