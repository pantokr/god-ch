import '../../../core/icons.dart';

import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../data/models/church_content.dart';
import 'block_theme.dart';

/// 최근 말씀 묵상 몇 개(보통 세 개)를 옆으로 넘기며 보는 캐러셀.
/// 카드를 누르면 그 말씀 묵상의 상세(내 묵상 쓰기 포함)가 열린다.
class DevotionCarousel extends StatefulWidget {
  const DevotionCarousel({
    super.key,
    required this.items,
    required this.theme,
    required this.onOpen,
    this.count = 3,
  });

  final List<ChurchContent> items;
  final BlockTheme theme;
  final void Function(ChurchContent) onOpen;

  /// 보여줄 최대 개수 (최신 글부터).
  final int count;

  @override
  State<DevotionCarousel> createState() => _DevotionCarouselState();
}

class _DevotionCarouselState extends State<DevotionCarousel> {
  PageController? _controller;
  double _fraction = 1;
  int _page = 0;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  PageController _controllerFor(double fraction) {
    if (_controller == null || _fraction != fraction) {
      _controller?.dispose();
      _fraction = fraction;
      _controller = PageController(
        viewportFraction: fraction,
        initialPage: _page,
      );
    }
    return _controller!;
  }

  void _go(int page) => _controller?.animateToPage(
    page,
    duration: const Duration(milliseconds: 320),
    curve: Curves.easeOutCubic,
  );

  @override
  Widget build(BuildContext context) {
    final items = widget.items.take(widget.count).toList();
    final t = widget.theme;
    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= 640;
        final controller = _controllerFor(wide ? 0.62 : 0.9);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: wide ? 300 : 340,
              child: PageView.builder(
                controller: controller,
                itemCount: items.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _Slide(
                    content: items[i],
                    theme: t,
                    onTap: () => widget.onOpen(items[i]),
                  ),
                ),
              ),
            ),
            if (items.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: '이전',
                      onPressed: _page > 0 ? () => _go(_page - 1) : null,
                      icon: const Icon(AppIcons.caretLeft),
                    ),
                    for (var i = 0; i < items.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _page ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _page
                              ? t.accent
                              : t.accent.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    IconButton(
                      tooltip: '다음',
                      onPressed: _page < items.length - 1
                          ? () => _go(_page + 1)
                          : null,
                      icon: const Icon(AppIcons.caretRight),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({
    required this.content,
    required this.theme,
    required this.onTap,
  });

  final ChurchContent content;
  final BlockTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: t.card(radius: AppRadius.panel),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.panel),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(AppIcons.bookOpen, size: 16, color: t.accent),
                    const SizedBox(width: 6),
                    Text(
                      fmtDate(content.date),
                      style: TextStyle(color: t.sub, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  content.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: t.accent,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Text(
                    content.body,
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                    style: readingStyle(context).copyWith(color: t.text),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '묵상 남기기',
                      style: TextStyle(
                        color: t.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Icon(AppIcons.caretRight, size: 18, color: t.accent),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
