import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/list_style_controller.dart';
import '../../../app/routes.dart';
import '../../../core/format.dart';
import '../../../core/icons.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/stat_icons.dart';
import '../../../data/models/church_content.dart';
import '../../../data/models/member.dart';
import '../../home/view/content_widgets.dart';
import '../view_model/devotions_view_model.dart';
import 'devotion_form.dart';

/// 성경: 말씀 묵상 목록. 줄마다 말씀과 묵상 미리보기가 있고, 오른쪽 가장자리에 조회수와 좋아요가 보인다.
/// 줄을 누르면 말씀 · 묵상 · 반응 · 댓글이 분리된 카드로 열린다 ([DevotionDetailPage]).
/// 모양은 알록달록 / 심플 중 고른다 ([ListStyleController]). 글을 올리는 것은 교역자 · 교회 운영자다.
class BiblePage extends StatelessWidget {
  const BiblePage({super.key, required this.me});

  final Member me;

  @override
  Widget build(BuildContext context) {
    final style = AppScope.read(context).listStyle;
    return ViewModelBuilder<DevotionsViewModel>(
      key: ValueKey('bible/${me.churchId}'),
      create: (context) =>
          DevotionsViewModel(AppScope.read(context).contents, me.churchId),
      builder: (context, vm) => SingleChildScrollView(
        child: PageFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageTitle(
                title: '성경',
                action: me.isStaff
                    ? FilledButton.icon(
                        onPressed: vm.busy ? null : () => _add(context, vm),
                        icon: const Icon(AppIcons.plus, size: 18),
                        label: const Text('추가'),
                      )
                    : null,
              ),
              StreamBuilder<List<ChurchContent>>(
                stream: vm.items,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return EmptyHint('불러오지 못했습니다\n${snap.error}');
                  }
                  final items = snap.data;
                  if (items == null) {
                    return const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (items.isEmpty) return const EmptyHint('말씀 없음');
                  return ListenableBuilder(
                    listenable: style,
                    builder: (context, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < items.length; i++)
                          style.style == ListStyle.colorful
                              ? _ColorfulItem(
                                  content: items[i],
                                  index: i,
                                  me: me,
                                )
                              : _MinimalItem(
                                  content: items[i],
                                  last: i == items.length - 1,
                                  me: me,
                                ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _add(BuildContext context, DevotionsViewModel vm) async {
    final result = await showDevotionForm(context);
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
}

/// 말씀 구절 한 줄 미리보기와 묵상 한 줄 미리보기.
class _Preview extends StatelessWidget {
  const _Preview({required this.content});

  final ChurchContent content;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                content.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              fmtDate(content.date),
              style: TextStyle(color: palette.muted, fontSize: 12),
            ),
          ],
        ),
        if (content.body.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            content.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: readingStyle(context).copyWith(fontSize: 14),
          ),
        ],
        if (content.meditation.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            content.meditation,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: palette.muted, fontSize: 13.5, height: 1.4),
          ),
        ],
      ],
    );
  }
}

/// 알록달록: 색이 옅게 깔린 카드, 왼쪽에 굵은 색 띠.
class _ColorfulItem extends StatelessWidget {
  const _ColorfulItem({
    required this.content,
    required this.index,
    required this.me,
  });

  final ChurchContent content;
  final int index;
  final Member me;

  @override
  Widget build(BuildContext context) {
    final hue = Pastel.hue(index);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push(Routes.devotion(me.churchId, content.id)),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          decoration: BoxDecoration(
            color: Pastel.fill(context, index),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: hue.withValues(alpha: 0.45)),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 8,
                  decoration: BoxDecoration(
                    color: hue,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(AppRadius.card),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
                    child: _Preview(content: content),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 14, 14, 14),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: StatIcons(
                      views: content.views,
                      likes: content.likes,
                      liked: content.likedBy.contains(me.id),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 심플: 테두리 없이 구분선만 있는 글 중심 목록.
class _MinimalItem extends StatelessWidget {
  const _MinimalItem({
    required this.content,
    required this.last,
    required this.me,
  });

  final ChurchContent content;
  final bool last;
  final Member me;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => context.push(Routes.devotion(me.churchId, content.id)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _Preview(content: content)),
                const SizedBox(width: 16),
                StatIcons(
                  views: content.views,
                  likes: content.likes,
                  liked: content.likedBy.contains(me.id),
                ),
              ],
            ),
          ),
        ),
        if (!last) Divider(height: 1, color: context.palette.border),
      ],
    );
  }
}
