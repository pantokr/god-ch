import '../../../core/widgets/app_loader.dart';
import '../../people/view/person_avatar.dart';
import '../../../core/widgets/trash_icon.dart';
import '../../../core/icons.dart';

import 'package:flutter/material.dart';

import '../../../core/screen_style.dart';

import '../../people/view/person_popup.dart';

import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/format.dart';
import '../../home/view/post_meta.dart';
import '../../../core/layout/sub_page.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/permission.dart';
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
    final back = Routes.section(me.churchId, ChurchSection.prayer);
    // 개인 설정의 글씨 크기 · 글꼴(명조)을 이 상세 화면에도 적용한다 (목록은 서랍 틀이 적용한다).
    return ScreenStyle(
      screen: 'prayer',
      child: ViewModelBuilder<PrayerDetailViewModel>(
        create: (context) {
          // 이 기기에서 연 글로 기록한다 (목록의 신규 표시가 바로 사라진다).
          AppScope.read(context).preferences
              .markSeen('p/${me.churchId}/$prayerId');
          return PrayerDetailViewModel(
            AppScope.read(context).prayers,
            me,
            prayerId,
          );
        },
        builder: (context, vm) => StreamBuilder<Prayer?>(
          stream: vm.prayer,
          initialData: initial,
          builder: (context, snap) {
            if (!snap.hasData &&
                !snap.hasError &&
                snap.data == null &&
                snap.connectionState == ConnectionState.waiting) {
              return SubPage(
                title: '중보기도',
                fallbackLocation: back,
                child: const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: AppLoader()),
                ),
              );
            }
            final p = snap.data;
            if (snap.hasError || vm.isHidden(p)) {
              return SubPage(
                title: '중보기도',
                fallbackLocation: back,
                child: const Card(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: Text('볼 수 없는 중보기도입니다.')),
                  ),
                ),
              );
            }
            return SubPage(
              title: '중보기도',
              fallbackLocation: back,
              actions: _actions(context, vm, p!),
              child: squareCards(
                child: _Body(vm: vm, prayer: p),
              ),
            );
          },
        ),
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
        style: TrashIcon.textStyle(context),
        icon: const TrashIcon(),
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
        router.go(Routes.section(me.churchId, ChurchSection.prayer));
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
          // 개인 설정: 중보기도 카드 색.
          color: AppScope.read(context).preferences
              .tintOf('prayer')
              .colorFor(Theme.of(context).brightness),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (p.deleted) ...[
                  const SizedBox(height: 12),
                  Text(
                    '삭제됨 · 사유: ${p.deleteReason ?? '-'}',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: 20),
                // 중보기도 본문은 책처럼 읽히도록 명조로 보여준다.
                SelectableText(p.content, style: readingStyle(context)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // 작성 정보는 본문과 분리한 카드에 둔다: 이름 → 날짜와 각종 정보 (말씀묵상과 같은 순서와 모양).
        PostInfoCard(
          meta: PostMeta(
            churchId: vm.me.churchId,
            author: PostAuthor(
              avatar: PersonTap(
                churchId: vm.me.churchId,
                uid: p.authorId,
                name: p.authorName,
                photoUrl: '',
                child: PersonAvatar(
                  churchId: vm.me.churchId,
                  uid: p.authorId,
                  name: p.authorName.isEmpty ? '?' : p.authorName,
                  radius: PostAuthor.avatarRadius,
                ),
              ),
              name: PersonTap(
                churchId: vm.me.churchId,
                uid: p.authorId,
                name: p.authorName,
                photoUrl: '',
                child: Text(
                  p.authorName.isEmpty ? '이름 없음' : p.authorName,
                  style: PostAuthor.nameStyle(context),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            date: fmtDateTime(p.createdAt),
            views: vm.settings.showViews ? p.views : null,
            isPrivate: !p.isPublic,
            affiliationId: p.affiliationId,
          ),
          // 반응(이모티콘 응원)
          footer:
              p.isPublic &&
                  !p.deleted &&
                  vm.settings.reactionsOn &&
                  vm.me.can(Permission.prayerEngage)
              ? ReactionBar(churchId: vm.me.churchId, prayerId: p.id)
              : null,
        ),
        const SizedBox(height: 16),
        if (p.isPublic && !p.deleted)
          EntrySection(
            title: '댓글',
            churchId: vm.me.churchId,
            entries: vm.comments,
            canWrite: vm.me.canPrayerComment && vm.settings.allowComments,
            hint: '댓글 쓰기',
            onSend: (text) => vm.addComment(p, text),
            canDelete: (e) => vm.canDeleteComment(e),
            onDelete: (e) => vm.deleteComment(p, e),
            canEdit: vm.canEditComment,
            onEdit: (e, text) => vm.editComment(p, e, text),
            errorOf: () => vm.error,
          ),
        if (!p.isPublic && vm.settings.privateResponses)
          EntrySection(
            title: '교역자 답변',
            churchId: vm.me.churchId,
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
