import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 사진 열람 팝업: 사진을 한 장씩 옆으로 넘기며 보고, 사진마다 회전·반전할 수 있다.
/// 화살표 버튼, 좌우 방향키, 화면 드래그로 넘긴다. 돌리거나 뒤집은 상태는 사진별로 따로 기억한다.
Future<void> showPhotoViewer(
  BuildContext context, {
  required List<String> urls,
  required String title,
  int initialIndex = 0,
}) => showDialog<void>(
  context: context,
  barrierColor: Colors.black,
  builder: (_) =>
      PhotoViewer(urls: urls, title: title, initialIndex: initialIndex),
);

/// 사진 한 장의 보기 상태: 90도 회전 횟수와 좌우·상하 반전.
class _View {
  int turns = 0;
  bool flipX = false;
  bool flipY = false;
}

class PhotoViewer extends StatefulWidget {
  const PhotoViewer({
    super.key,
    required this.urls,
    required this.title,
    this.initialIndex = 0,
  });

  final List<String> urls;
  final String title;
  final int initialIndex;

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  late final PageController _pages = PageController(
    initialPage: widget.initialIndex,
  );
  late final List<_View> _views = [for (final _ in widget.urls) _View()];
  final _focus = FocusNode();
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _pages.dispose();
    _focus.dispose();
    super.dispose();
  }

  _View get _current => _views[_index];

  void _go(int to) {
    if (to < 0 || to >= widget.urls.length) return;
    _pages.animateToPage(
      to,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _change(VoidCallback f) => setState(f);

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _go(_index - 1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _go(_index + 1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final last = widget.urls.length - 1;
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pages,
              itemCount: widget.urls.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) =>
                  _Photo(url: widget.urls[i], view: _views[i]),
            ),
            // 위: 제목과 쪽수, 닫기
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        '${_index + 1} / ${widget.urls.length}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      IconButton(
                        tooltip: '닫기',
                        color: Colors.white,
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 양옆: 이전·다음
            if (_index > 0)
              Align(
                alignment: Alignment.centerLeft,
                child: _Arrow(
                  icon: Icons.chevron_left,
                  onTap: () => _go(_index - 1),
                ),
              ),
            if (_index < last)
              Align(
                alignment: Alignment.centerRight,
                child: _Arrow(
                  icon: Icons.chevron_right,
                  onTap: () => _go(_index + 1),
                ),
              ),
            // 아래: 회전 · 반전 도구
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _Tool(
                            icon: Icons.rotate_left,
                            tooltip: '왼쪽으로 회전',
                            onTap: () => _change(
                              () => _current.turns = (_current.turns + 3) % 4,
                            ),
                          ),
                          _Tool(
                            icon: Icons.rotate_right,
                            tooltip: '오른쪽으로 회전',
                            onTap: () => _change(
                              () => _current.turns = (_current.turns + 1) % 4,
                            ),
                          ),
                          _Tool(
                            icon: Icons.flip,
                            tooltip: '좌우 반전',
                            active: _current.flipX,
                            onTap: () =>
                                _change(() => _current.flipX = !_current.flipX),
                          ),
                          _Tool(
                            icon: Icons.flip,
                            quarterTurns: 1,
                            tooltip: '상하 반전',
                            active: _current.flipY,
                            onTap: () =>
                                _change(() => _current.flipY = !_current.flipY),
                          ),
                          _Tool(
                            icon: Icons.restart_alt,
                            tooltip: '원래대로',
                            onTap: () => _change(() {
                              _current.turns = 0;
                              _current.flipX = false;
                              _current.flipY = false;
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 사진 한 장: 회전·반전을 적용해 화면 안에 맞춰 보여준다.
class _Photo extends StatelessWidget {
  const _Photo({required this.url, required this.view});

  final String url;
  final _View view;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // 위 제목줄과 아래 도구 줄에 가리지 않게 비운다.
      padding: const EdgeInsets.fromLTRB(56, 64, 56, 84),
      child: Center(
        child: Transform.flip(
          flipX: view.flipX,
          flipY: view.flipY,
          // RotatedBox는 90도 돌리면 가로·세로 제약도 바꿔서, 돌린 사진이 칸 안에 맞게 들어온다.
          child: RotatedBox(
            quarterTurns: view.turns,
            child: Image.network(
              url,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white70),
                    ),
              errorBuilder: (context, error, stack) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white54,
                size: 48,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: IconButton.filledTonal(
      onPressed: onTap,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.18),
        foregroundColor: Colors.white,
      ),
    ),
  );
}

class _Tool extends StatelessWidget {
  const _Tool({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
    this.quarterTurns = 0,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;
  final int quarterTurns;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onTap,
    color: active ? const Color(0xFFC6FF3D) : Colors.white,
    icon: RotatedBox(quarterTurns: quarterTurns, child: Icon(icon)),
  );
}
