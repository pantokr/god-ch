import '../../../core/widgets/app_loader.dart';

import 'package:flutter/material.dart';

import '../../people/view/person_popup.dart';

import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/widgets/like_button.dart';
import '../../../core/widgets/trash_icon.dart';
import '../../../core/format.dart';
import '../../../core/icons.dart';
import '../../../core/layout/confirm_dialog.dart';
import '../../../core/layout/sub_page.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../home/view/post_meta.dart';
import '../../../core/widgets/thumbnail_avatar.dart';
import '../../../data/models/permission.dart';
import '../../../data/models/affiliation.dart';
import '../../../data/models/church_content.dart';
import '../../../data/models/devotion_settings.dart';
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
                      child: Center(child: AppLoader()),
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
              if (me.can(Permission.devotionWrite))
                TextButton.icon(
                  icon: const Icon(AppIcons.pencilSimple, size: 18),
                  label: const Text('수정'),
                  onPressed: () => _edit(context, vm, c),
                ),
              // 삭제: 본인 글은 글을 쓸 수 있으면 누구나, 타인 글은 타인 글 삭제 권한이 있어야 한다.
              if (me.can(
                c.authorId == me.id
                    ? Permission.devotionWrite
                    : Permission.devotionDeleteOthers,
              ))
                TextButton.icon(
                  style: TrashIcon.textStyle(context),
                  icon: const TrashIcon(),
                  label: const Text('삭제'),
                  onPressed: () => _delete(context, vm, c, back),
                ),
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _VerseCard(
                  content: c,
                  churchId: me.churchId,
                  showAuthor: vm.settings.showAuthor,
                  showViews: vm.settings.showViews,
                ),
                const SizedBox(height: 12),
                _MeditationCard(content: c),
                const SizedBox(height: 12),
                // 작성 정보는 본문과 묵상 다음에 둔다.
                _AuthorInfoCard(
                  content: c,
                  churchId: me.churchId,
                  showAuthor: vm.settings.showAuthor,
                  showViews: vm.settings.showViews,
                ),
                // 하트 · 조회수 줄은 위 내용과 여유를 둔다.
                const SizedBox(height: 20),
                _ReactionCard(
                  content: c,
                  me: me,
                  vm: vm,
                  settings: vm.settings,
                ),
                const SizedBox(height: 12),
                if (vm.settings.allowReflections ||
                    vm.settings.reflectionsPublic)
                  ReflectionsCard(
                    devotionId: c.id,
                    me: me,
                    publicList: vm.settings.reflectionsPublic,
                    canWrite:
                        vm.settings.allowReflections &&
                        me.can(Permission.devotionComment),
                  ),
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
    final result = await showDevotionForm(
      context,
      churchId: me.churchId,
      visible: me.sees,
      initial: c,
    );
    if (result == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await vm.save(
      title: result.title,
      body: result.body,
      meditation: result.meditation,
      date: result.date,
      affiliationId: result.affiliationId,
      isPrivate: result.isPrivate,
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
      danger: true,
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
      shape: context.edgedCardShape,
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

/// 성경 본문 카드: 색이 깊게 깔린 큰 카드에 인용 부호, 구절 이름표, 본문을 크게 앉힌다.
/// 글쓴이와 날짜는 묵상 다음의 작성 정보 카드에 둔다.
class _VerseCard extends StatelessWidget {
  const _VerseCard({
    required this.content,
    required this.churchId,
    this.showAuthor = true,
    this.showViews = true,
  });

  final ChurchContent content;
  final String churchId;

  /// 조회수 공개 설정.
  final bool showViews;

  /// 글쓴이 공개 설정.
  final bool showAuthor;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;
    // 베이지 바탕 (다크에서는 어두운 베이지). 글자는 본문 글자색을 쓴다.
    final paper = dark ? const Color(0xFF2B2620) : const Color(0xFFF6EFE3);
    final edge = dark ? const Color(0xFF3D362D) : const Color(0xFFE6DCCB);
    final onColor = palette.ink;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(AppRadius.panel),
        border: Border.all(color: edge),
        boxShadow: [
          BoxShadow(
            color: (dark ? Colors.black : const Color(0xFF6B5A3E)).withValues(
              alpha: dark ? 0.4 : 0.18,
            ),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.panel),
        child: Stack(
          children: [
            // 큰 인용 부호 장식.
            Positioned(
              right: 12,
              top: -18,
              child: Text(
                '”',
                style: TextStyle(
                  fontSize: 160,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: onColor.withValues(alpha: 0.13),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: onColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: onColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(AppIcons.bookOpen, size: 16, color: onColor),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              content.title,
                              style: TextStyle(
                                color: onColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SelectableText(
                    content.body,
                    style: readingStyle(context).copyWith(
                      color: onColor,
                      fontSize: 19,
                      height: 1.9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 작성 정보 카드: 글쓴이(프로필 · 이름)와 날짜 · 조회수 등. 본문과 묵상 아래에 둔다.
class _AuthorInfoCard extends StatelessWidget {
  const _AuthorInfoCard({
    required this.content,
    required this.churchId,
    this.showAuthor = true,
    this.showViews = true,
  });

  final ChurchContent content;
  final String churchId;
  final bool showViews;
  final bool showAuthor;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final onColor = palette.ink;
    return Card(
      shape: context.edgedCardShape,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (content.authorName.isNotEmpty && showAuthor) ...[
              Row(
                children: [
                  PersonTap(
                    churchId: churchId,
                    uid: content.authorId,
                    name: content.authorName,
                    photoUrl: content.authorPhotoUrl,
                    child: ThumbnailAvatar(
                      name: content.authorName,
                      url: content.authorPhotoUrl,
                      radius: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: PersonTap(
                        churchId: churchId,
                        uid: content.authorId,
                        name: content.authorName,
                        photoUrl: content.authorPhotoUrl,
                        child: Text(
                          content.authorName,
                          style: TextStyle(
                            color: onColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            PostMeta(
              churchId: churchId,
              date: fmtDateAt(content.date, content.createdAt),
              views: showViews ? content.views : null,
              isPrivate: content.isPrivate,
              affiliationId: content.affiliationId,
              color: onColor.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }
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
    required this.settings,
  });

  final ChurchContent content;
  final Member me;
  final DevotionDetailViewModel vm;
  final DevotionSettings settings;

  @override
  Widget build(BuildContext context) {
    final liked = content.likedBy.contains(me.id);
    return Card(
      shape: context.edgedCardShape,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(
          children: [
            if (settings.allowLikes && me.can(Permission.devotionReact))
              LikeButton(
                liked: liked,
                count: content.likes,
                showCount: settings.showLikeCount,
                onTap: () => vm.setLike(!liked),
              ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
