import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme.dart';
import '../../../data/models/church_content.dart';
import 'content_widgets.dart';

/// 메인 맨 위의 공지사항 캐러셀: 썸네일을 크게 보여주고 몇 초마다 자동으로 넘어간다.
/// 좌우 화살표와 점으로도 넘길 수 있고, 누르면 [onOpen]으로 공지를 연다.
class NoticeCarousel extends StatefulWidget {
  const NoticeCarousel({
    super.key,
    required this.notices,
    required this.onOpen,
  });

  final List<ChurchContent> notices;
  final void Function(ChurchContent notice) onOpen;

  /// 캐러셀의 가로:세로 비율. 공지가 없을 때도 같은 높이를 잡는 데 쓴다.
  static double aspectOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width < kNarrow ? 16 / 10 : 16 / 6;

  @override
  State<NoticeCarousel> createState() => _NoticeCarouselState();
}

class _NoticeCarouselState extends State<NoticeCarousel> {
  static const _interval = Duration(seconds: 5);
  static const _slide = Duration(milliseconds: 350);

  final _controller = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _restartTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  int get _count => widget.notices.length;

  void _restartTimer() {
    _timer?.cancel();
    if (_count < 2) return;
    _timer = Timer.periodic(_interval, (_) => _go(_index + 1));
  }

  void _go(int to) {
    if (!_controller.hasClients || _count == 0) return;
    _controller.animateToPage(
      (to % _count + _count) % _count,
      duration: _slide,
      curve: Curves.easeOut,
    );
  }

  @override
  void didUpdateWidget(NoticeCarousel old) {
    super.didUpdateWidget(old);
    if (old.notices.length != _count) {
      if (_index >= _count) _index = 0;
      _restartTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < kNarrow;
    return AspectRatio(
      aspectRatio: NoticeCarousel.aspectOf(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: _count,
              onPageChanged: (i) {
                setState(() => _index = i);
                // 직접 넘겼을 때 곧바로 다시 넘어가지 않도록 시간을 다시 센다.
                _restartTimer();
              },
              itemBuilder: (context, i) => _Slide(
                notice: widget.notices[i],
                onTap: () => widget.onOpen(widget.notices[i]),
              ),
            ),
            if (_count > 1) ...[
              if (!narrow) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: _Arrow(
                    icon: Icons.chevron_left,
                    onTap: () => _go(_index - 1),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: _Arrow(
                    icon: Icons.chevron_right,
                    onTap: () => _go(_index + 1),
                  ),
                ),
              ],
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < _count; i++)
                        Container(
                          width: i == _index ? 18 : 7,
                          height: 7,
                          margin: const EdgeInsets.only(left: 5),
                          decoration: BoxDecoration(
                            color: i == _index ? Colors.white : Colors.white54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.notice, required this.onTap});

  final ChurchContent notice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < kNarrow;
    return InkWell(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 가로 배경. 없으면 썸네일을 배경으로 깐다.
          ContentImage(
            notice.background ?? notice.thumbnail,
            icon: Icons.campaign_outlined,
          ),
          const ColoredBox(color: Color(0x73000000)),
          // 왼쪽에 4:3 썸네일, 오른쪽에 날짜와 제목.
          LayoutBuilder(
            builder: (context, box) {
              const pad = 18.0;
              // 4:3 비율을 지키되, 글자 자리를 위해 폭의 40%를 넘기지 않는다.
              final maxH = box.maxHeight - pad * 2;
              final thumbW = (maxH * kThumbnailAspect).clamp(
                0.0,
                box.maxWidth * 0.4,
              );
              final thumbH = thumbW / kThumbnailAspect;
              return Padding(
                // 넓은 화면에서는 좌우 화살표 버튼과 겹치지 않게 비운다.
                padding: EdgeInsets.fromLTRB(narrow ? pad : 64, pad, pad, pad),
                child: Row(
                  children: [
                    if (notice.thumbnail != null)
                      Container(
                        width: thumbW,
                        height: thumbH,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: Colors.white24),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ContentImage(
                          notice.thumbnail,
                          icon: Icons.campaign_outlined,
                        ),
                      ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Padding(
                        // 오른쪽 아래의 점 표시와 겹치지 않게 비운다.
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fmtDate(notice.date),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              notice.title,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontSize: narrow ? 17 : 22,
                                  ),
                            ),
                            if (!narrow && notice.body.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                notice.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: IconButton.filledTonal(
        onPressed: onTap,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          backgroundColor: Colors.black38,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
