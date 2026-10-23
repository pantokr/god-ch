import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/format.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/church_content.dart';
import '../../../data/models/member.dart';
import '../view_model/content_detail_view_model.dart';
import 'content_widgets.dart';

/// 콘텐츠 한 건 자세히 보기. 종류에 따라 사진 여러 장, 유튜브 열기 버튼 등이 붙는다.
class ContentDetailPage extends StatelessWidget {
  const ContentDetailPage({
    super.key,
    required this.me,
    required this.kind,
    required this.contentId,
  });

  final Member me;
  final ContentKind kind;
  final String contentId;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ContentDetailViewModel>(
      create: (context) => ContentDetailViewModel(
        AppScope.read(context).contents,
        me.churchId,
        kind,
        contentId,
      ),
      builder: (context, vm) => StreamBuilder<ChurchContent?>(
        stream: vm.content,
        builder: (context, snap) {
          final Widget body;
          if (snap.hasError) {
            body = EmptyHint('불러오지 못했습니다\n${snap.error}');
          } else if (snap.connectionState == ConnectionState.waiting) {
            body = const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (snap.data == null) {
            body = const EmptyHint('삭제되었거나 없는 글이에요.');
          } else {
            body = _Detail(content: snap.data!);
          }
          return SingleChildScrollView(
            child: PageFrame(
              maxWidth: 760,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go(Routes.contentList(me.churchId, kind)),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: Text('${kind.label} 목록'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  body,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.content});

  final ChurchContent content;

  @override
  Widget build(BuildContext context) {
    final id = youtubeId(content.videoUrl);
    final watchUri = id == null
        ? null
        : Uri.parse('https://www.youtube.com/watch?v=$id');
    final date = content.kind == ContentKind.event
        ? '${fmtDate(content.date)} (${weekdayLabel(content.date)})'
        : fmtDate(content.date);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(content.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(date, style: TextStyle(color: context.palette.muted)),
        const SizedBox(height: 20),
        if (watchUri != null) ...[
          InkWell(
            onTap: () =>
                launchUrl(watchUri, mode: LaunchMode.externalApplication),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ContentImage(
                      youtubeThumbnail(content.videoUrl),
                      icon: Icons.smart_display_outlined,
                    ),
                    const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        size: 64,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () =>
                  launchUrl(watchUri, mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('유튜브에서 보기'),
            ),
          ),
          const SizedBox(height: 20),
        ],
        // 공지는 3:4 썸네일 한 장만 보여 주고(둘째 이미지는 캐러셀 배경), 사진첩은 모두 보여 준다.
        if (content.kind == ContentKind.notice &&
            content.thumbnail != null) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: AspectRatio(
                aspectRatio: kThumbnailAspect,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: ContentImage(content.thumbnail),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ] else
          for (final url in content.imageUrls) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: AspectRatio(aspectRatio: 4 / 3, child: ContentImage(url)),
            ),
            const SizedBox(height: 12),
          ],
        if (content.body.isNotEmpty)
          SelectableText(content.body, style: readingStyle(context)),
        const SizedBox(height: 24),
      ],
    );
  }
}
