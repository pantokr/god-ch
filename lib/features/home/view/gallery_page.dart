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

/// 겹겹이 쌓인 사진 카드: 대표 사진(첫 장) 한 장이 앞에 있고, 그 뒤로 다른 사진들이 살짝 비껴 쌓여 있다.
/// 행사 하나가 한 칸이다. 누르면 사진 열람 팝업이 열린다.
class StackedAlbumCard extends StatelessWidget {
  const StackedAlbumCard({super.key, required this.album});

  final ChurchContent album;

  /// 뒤에 깔리는 장 수와 기울기(라디안)·밀림. 사진이 모자라면 빈 종이가 깔린다.
  static const _behind = [(angle: -0.09, dx: -6.0), (angle: 0.07, dx: 6.0)];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final urls = album.imageUrls;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => showPhotoViewer(context, urls: urls, title: album.title),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: Padding(
                  // 기울어진 뒷장이 칸 밖으로 잘리지 않게 안쪽으로 비운다.
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  child: Stack(
                    fit: StackFit.expand,
                    clipBehavior: Clip.none,
                    children: [
                      for (var i = _behind.length; i >= 1; i--)
                        Transform.translate(
                          offset: Offset(_behind[i - 1].dx, 0),
                          child: Transform.rotate(
                            angle: _behind[i - 1].angle,
                            child: _Sheet(
                              url: i < urls.length ? urls[i] : null,
                            ),
                          ),
                        ),
                      _Sheet(url: urls.first, count: urls.length),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                album.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                fmtDate(album.date),
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 쌓인 사진 한 장: 흰 테두리를 두른 사진 (사진이 없으면 빈 종이). [count]가 있으면 사진 수를 붙인다.
class _Sheet extends StatelessWidget {
  const _Sheet({required this.url, this.count});

  final String? url;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: palette.border),
        boxShadow: AppShadow.soft(context),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (url != null)
                ContentImage(url!)
              else
                ColoredBox(color: palette.border.withValues(alpha: 0.5)),
              if (count != null && count! > 1)
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(AppRadius.control),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
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
