import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/format.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/church_content.dart';
import '../../../data/models/member.dart';
import '../view_model/gallery_view_model.dart';
import 'content_widgets.dart';
import 'photo_viewer.dart';

/// 갤러리 탭: 사진첩에 올라온 글을 제목과 사진 뭉치로 보여준다.
/// 글을 누르면 사진을 한 장씩 넘기며 보는 열람 팝업(회전·반전 가능)이 열린다.
class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key, required this.me});

  final Member me;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<GalleryViewModel>(
      key: ValueKey(me.churchId),
      create: (context) =>
          GalleryViewModel(AppScope.read(context).contents, me.churchId),
      builder: (context, vm) => SingleChildScrollView(
        child: PageFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageTitle(title: '갤러리'),
              ContentStream(
                stream: vm.albums,
                builder: (context, albums) {
                  // 사진이 없는 글은 갤러리에 보이지 않는다.
                  final withPhotos = [
                    for (final a in albums)
                      if (a.imageUrls.isNotEmpty) a,
                  ];
                  if (withPhotos.isEmpty) {
                    return const EmptyHint('아직 올라온 사진이 없어요.');
                  }
                  return ColumnWrap(
                    wide: 2,
                    narrow: 1,
                    children: [for (final a in withPhotos) AlbumCard(album: a)],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 갤러리에 올린 글 한 건: 제목, 날짜 · 사진 수, 그리고 사진 뭉치. 누르면 사진 열람 팝업.
class AlbumCard extends StatelessWidget {
  const AlbumCard({super.key, required this.album});

  final ChurchContent album;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final radius = BorderRadius.circular(AppRadius.card);
    final urls = album.imageUrls;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: radius,
        border: Border.all(color: palette.border.withValues(alpha: 0.7)),
        boxShadow: AppShadow.soft(context),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () =>
                showPhotoViewer(context, urls: urls, title: album.title),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PhotoBundle(urls: urls),
                  const SizedBox(height: 12),
                  Text(
                    album.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${fmtDate(album.date)} · 사진 ${urls.length}장',
                    style: TextStyle(color: palette.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 사진 뭉치: 한 장이면 가득, 두 장이면 반반, 세 장 이상이면 큰 사진 하나와 작은 사진 둘 (남은 수는 "+N").
class PhotoBundle extends StatelessWidget {
  const PhotoBundle({super.key, required this.urls});

  final List<String> urls;

  static const _gap = 4.0;

  @override
  Widget build(BuildContext context) {
    Widget photo(int i) => SizedBox.expand(child: ContentImage(urls[i]));
    final n = urls.length;
    final Widget layout;
    if (n == 1) {
      layout = photo(0);
    } else if (n == 2) {
      layout = Row(
        children: [
          Expanded(child: photo(0)),
          const SizedBox(width: _gap),
          Expanded(child: photo(1)),
        ],
      );
    } else {
      layout = Row(
        children: [
          Expanded(flex: 2, child: photo(0)),
          const SizedBox(width: _gap),
          Expanded(
            child: Column(
              children: [
                Expanded(child: photo(1)),
                const SizedBox(height: _gap),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      photo(2),
                      if (n > 3)
                        ColoredBox(
                          color: Colors.black54,
                          child: Center(
                            child: Text(
                              '+${n - 3}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: layout,
      ),
    );
  }
}
