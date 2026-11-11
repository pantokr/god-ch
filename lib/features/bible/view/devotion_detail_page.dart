import '../../../core/widgets/app_loader.dart';

import 'package:flutter/material.dart';

import '../../../core/screen_style.dart';

import '../../../core/widgets/toast.dart';

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
import 'verse_card.dart';
import 'reflections_card.dart';

/// 주소 `/churches/:cid/devotion/:id`: 말씀 상세. 말씀 · 묵상 · 반응 · 댓글이 분리된 카드로 보인다.
class DevotionDetailPage extends StatelessWidget {
  const DevotionDetailPage({super.key, required this.me, required this.id});

  final Member me;
  final String id;

  @override
  Widget build(BuildContext context) {
    final back = Routes.section(me.churchId, ChurchSection.bible);
    // 개인 설정의 글씨 크기 · 글꼴(명조)을 이 상세 화면에도 적용한다 (목록은 서랍 틀이 적용한다).
    return ScreenStyle(
      screen: 'bible',
      child: ViewModelBuilder<DevotionDetailViewModel>(
        key: ValueKey('devotion/$id'),
        create: (context) {
          // 이 기기에서 연 글로 기록한다 (목록의 신규 표시가 바로 사라진다).
          AppScope.read(context).preferences.markSeen('d/${me.churchId}/$id');
          return DevotionDetailViewModel(
            AppScope.read(context).contents,
            me.churchId,
            id,
          );
        },
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
                if (me.can(Permission.devotionPost))
                  TextButton.icon(
                    icon: const Icon(AppIcons.pencilSimple, size: 18),
                    label: const Text('수정'),
                    onPressed: () => _edit(context, vm, c),
                  ),
                // 삭제: 본인 글은 글을 쓸 수 있으면 누구나, 타인 글은 타인 글 삭제 권한이 있어야 한다.
                // 타인 글은 글 관리 범위가 전체여야 한다 (본인만이면 본인 글만).
                if (c.authorId == me.id
                    ? me.can(Permission.devotionPost)
                    : me.canAll(Permission.devotionPost))
                  TextButton.icon(
                    style: TrashIcon.textStyle(context),
                    icon: const TrashIcon(),
                    label: const Text('삭제'),
                    onPressed: () => _delete(context, vm, c, back),
                  ),
              ],
              // 글자를 끌어 선택해 복사할 수 있다 (말씀 · 묵상 · 나눔 모두).
              child: SelectionArea(
                child: squareCards(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Passages(content: c),
                      const SizedBox(height: 12),
                      // 작성 정보는 본문과 묵상 다음에 둔다. 좋아요 · 조회수도 같은 카드 안에 있다.
                      _AuthorInfoCard(
                        content: c,
                        churchId: me.churchId,
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
                              me.can(Permission.devotionEngage),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
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
      extras: result.extras,
      date: result.date,
      affiliationId: result.affiliationId,
      isPrivate: result.isPrivate,
    );
    if (!ok && vm.error != null) {
      showToastOn(messenger, vm.error!);
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
      // 개인 설정: 말씀묵상 카드 색 (묵상 카드).
      color: bibleTint(context),
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

/// 작성 정보 카드: 글쓴이(프로필 · 이름)와 작성일이 한 줄에 나란히, 그 아래 조회수 · 공개 범위, 맨 아래 좋아요.
/// 본문과 묵상 아래에 두고, 좋아요 · 조회수도 이 카드 안에 있다.
class _AuthorInfoCard extends StatelessWidget {
  const _AuthorInfoCard({
    required this.content,
    required this.churchId,
    required this.me,
    required this.vm,
    required this.settings,
  });

  final ChurchContent content;
  final String churchId;
  final Member me;
  final DevotionDetailViewModel vm;
  final DevotionSettings settings;

  @override
  Widget build(BuildContext context) {
    final date = fmtDateAt(content.date, content.createdAt);
    final showByline = content.authorName.isNotEmpty && settings.showAuthor;
    final liked = content.likedBy.contains(me.id);
    final author = showByline
        ? PostAuthor(
            avatar: PersonTap(
              churchId: churchId,
              uid: content.authorId,
              name: content.authorName,
              photoUrl: content.authorPhotoUrl,
              child: ThumbnailAvatar(
                name: content.authorName,
                url: content.authorPhotoUrl,
                radius: PostAuthor.avatarRadius,
              ),
            ),
            name: PersonTap(
              churchId: churchId,
              uid: content.authorId,
              name: content.authorName,
              photoUrl: content.authorPhotoUrl,
              child: Text(
                content.authorName,
                style: PostAuthor.nameStyle(context),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
        : null;
    return PostInfoCard(
      shape: context.edgedCardShape,
      color: bibleTint(context),
      meta: PostMeta(
        churchId: churchId,
        author: author,
        date: date,
        views: settings.showViews ? content.views : null,
        isPrivate: content.isPrivate,
        affiliationId: content.affiliationId,
      ),
      footer: settings.allowLikes && me.can(Permission.devotionEngage)
          ? LikeButton(
              liked: liked,
              count: content.likes,
              showCount: settings.showLikeCount,
              onTap: () => vm.setLike(!liked),
            )
          : null,
    );
  }
}

class _MeditationCard extends StatelessWidget {
  const _MeditationCard({required this.meditation});

  final String meditation;

  @override
  Widget build(BuildContext context) => _Section(
    icon: AppIcons.sparkles,
    label: '묵상',
    child: meditation.isEmpty
        ? Text('묵상 없음', style: TextStyle(color: context.palette.muted))
        // 묵상은 줄이지 않고 전부 보인다 (더보기는 말씀에만 있다).
        : Text(meditation, style: readingStyle(context)),
  );
}

/// 말씀 · 묵상이 한 벌이면 그대로, 여러 벌이면 위의 이름표(구절)로 하나씩 골라 본다.
/// 한 화면에는 한 벌만 보여서 묵상이 10개여도 페이지가 길어지지 않는다.
class _Passages extends StatefulWidget {
  const _Passages({required this.content});

  final ChurchContent content;

  @override
  State<_Passages> createState() => _PassagesState();
}

class _PassagesState extends State<_Passages> {
  int _index = 0;

  void _go(int to, int count) {
    if (to < 0 || to >= count) return;
    setState(() => _index = to);
  }

  @override
  Widget build(BuildContext context) {
    final passages = widget.content.passages;
    final count = passages.length;
    final i = _index < count ? _index : 0;
    final p = passages[i];
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VerseCard(title: p.title, body: p.body),
        const SizedBox(height: 12),
        _MeditationCard(meditation: p.meditation),
      ],
    );
    if (count == 1) return body;
    return GestureDetector(
      // 좌우로 밀어서도 넘길 수 있다.
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v < -200) _go(i + 1, count);
        if (v > 200) _go(i - 1, count);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PagerBar(
            index: i,
            count: count,
            title: p.title,
            onPrev: i == 0 ? null : () => _go(i - 1, count),
            onNext: i == count - 1 ? null : () => _go(i + 1, count),
            onDot: (k) => _go(k, count),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: KeyedSubtree(key: ValueKey(i), child: body),
          ),
        ],
      ),
    );
  }
}

/// 여러 묵상을 넘기는 막대: 좌우 화살표, 가운데에 "2 / 10"과 구절 이름, 아래에 점 표시.
/// 색은 보라색 없이 본문 글자색 하나만 쓴다.
class _PagerBar extends StatelessWidget {
  const _PagerBar({
    required this.index,
    required this.count,
    required this.title,
    required this.onPrev,
    required this.onNext,
    required this.onDot,
  });

  final int index;
  final int count;
  final String title;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final ValueChanged<int> onDot;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: bibleTint(context) ?? palette.surface,
      shape: context.edgedCardShape,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            IconButton(
              tooltip: '이전 묵상',
              onPressed: onPrev,
              icon: const Icon(AppIcons.caretLeft),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${index + 1} / $count',
                          style: TextStyle(color: palette.muted, fontSize: 13),
                        ),
                        TextSpan(
                          text: '   $title',
                          style: TextStyle(color: palette.ink, fontSize: 16),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      for (var k = 0; k < count; k++)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onDot(k),
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: Container(
                              width: k == index ? 18 : 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: k == index
                                    ? palette.ink
                                    : palette.border,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: '다음 묵상',
              onPressed: onNext,
              icon: const Icon(AppIcons.caretRight),
            ),
          ],
        ),
      ),
    );
  }
}
