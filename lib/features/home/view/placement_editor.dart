import 'package:flutter/material.dart';

import '../../../core/icons.dart';
import '../../../core/theme.dart';
import '../../../data/models/page_layout.dart';
import 'page_icons.dart';

/// 배치 설정: 실제 앱과 비슷한 화면(왼쪽에 열린 좌측 탭, 가운데 홈, 아래 하단 탭) 안에서
/// 페이지를 길게 눌러 끌어다 놓아 위치와 순서를 정한다.
/// - 좌측 탭 · 홈: 놓은 자리가 곧 순서다 (다른 페이지 위에 놓으면 그 앞에 들어간다).
/// - 하단 왼쪽 · 오른쪽 버튼: 한 자리에 하나. 이미 있던 페이지는 홈(홈에 둘 수 없으면 좌측 탭)으로 밀려난다.
/// 놓을 수 없는 자리(좌측 탭이 꽉 참, 템플릿 페이지를 홈으로)는 빨갛게 보인다.
/// 저장하면 [onSave]가 호출되고, 오류 문구를 돌려주면 그대로 보여 준다 (null이면 성공하고 닫힌다).
class PlacementEditor extends StatefulWidget {
  const PlacementEditor({
    super.key,
    required this.pages,
    required this.onSave,
    this.focusId,
  });

  final List<PageConfig> pages;

  /// 눈에 띄게 보여줄 페이지 (배치 설정을 연 페이지).
  final String? focusId;
  final Future<String?> Function(List<PageConfig> pages) onSave;

  @override
  State<PlacementEditor> createState() => _PlacementEditorState();
}

class _PlacementEditorState extends State<PlacementEditor> {
  static const _phoneWidth = 340.0;
  static const _phoneHeight = 540.0;
  static const _drawerWidth = 150.0;

  late List<PageConfig> _pages = List.of(widget.pages);
  bool _saving = false;
  String? _error;

  bool get _changed {
    if (_pages.length != widget.pages.length) return true;
    for (var i = 0; i < _pages.length; i++) {
      if (_pages[i].id != widget.pages[i].id ||
          _pages[i].group != widget.pages[i].group) {
        return true;
      }
    }
    return false;
  }

  List<PageConfig> _in(PageGroup g) => [
    for (final p in _pages)
      if (p.group == g) p,
  ];

  /// [id] 페이지를 [to] 자리로 옮긴다. [before]가 있으면 그 페이지 앞에, 없으면 그 자리의 맨 끝에 넣는다.
  void _move(String id, PageGroup to, {String? before}) {
    final placed = PageConfig.place(_pages, id, to);
    if (placed == null) {
      setState(() => _error = '${to.label}에는 더 둘 수 없어요.');
      return;
    }
    final moved = placed.firstWhere((p) => p.id == id);
    final list = placed.where((p) => p.id != id).toList();
    var at = list.length;
    if (before != null) {
      final i = list.indexWhere((p) => p.id == before);
      if (i >= 0) at = i;
    } else {
      final last = list.lastIndexWhere((p) => p.group == to);
      if (last >= 0) at = last + 1;
    }
    list.insert(at, moved);
    setState(() {
      _pages = list;
      _error = null;
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onSave(_pages);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  /// [g] 자리에 끌어다 놓을 수 있는 영역. [before]가 있으면 그 페이지 앞에 넣는 칸이다.
  Widget _drop(
    PageGroup g,
    Widget Function(bool hot, bool bad) builder, {
    String? before,
  }) => DragTarget<String>(
    onWillAcceptWithDetails: (d) =>
        !_saving &&
        d.data != before &&
        PageConfig.place(_pages, d.data, g) != null,
    onAcceptWithDetails: (d) => _move(d.data, g, before: before),
    builder: (context, candidate, rejected) =>
        builder(candidate.isNotEmpty, rejected.isNotEmpty),
  );

  /// 끌 수 있는 페이지 하나. [child]는 놓인 모양이고, 다른 페이지를 이 위에 놓으면 이 앞에 들어간다.
  Widget _item(PageConfig page, Widget Function(bool hot) child) {
    final focused = page.id == widget.focusId;
    Widget body(bool hot) => DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hot
              ? context.palette.brand
              : focused
              ? context.palette.brand.withValues(alpha: 0.6)
              : Colors.transparent,
          width: hot ? 2 : 1.5,
        ),
      ),
      child: child(hot),
    );
    return LongPressDraggable<String>(
      data: page.id,
      delay: const Duration(milliseconds: 150),
      feedback: Material(
        color: Colors.transparent,
        elevation: 6,
        child: _Chip(page: page),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: body(false)),
      child: _drop(page.group, (hot, bad) => body(hot), before: page.id),
    );
  }

  Widget _zoneBox({
    required bool hot,
    required bool bad,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(8),
  }) {
    final palette = context.palette;
    final error = Theme.of(context).colorScheme.error;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: hot ? palette.brand.withValues(alpha: 0.1) : null,
        border: Border.all(
          color: hot
              ? palette.brand
              : bad
              ? error
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: child,
    );
  }

  Widget _homeZone() {
    final palette = context.palette;
    final items = _in(PageGroup.home);
    return _drop(
      PageGroup.home,
      (hot, bad) => _zoneBox(
        hot: hot,
        bad: bad,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final p in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _item(
                  p,
                  (hot) => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: palette.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          pageIconOf(p.icon).outlined,
                          size: 18,
                          color: palette.brand,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            p.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    '홈',
                    style: TextStyle(color: palette.muted, fontSize: 12),
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _drawer() {
    final palette = context.palette;
    final items = _in(PageGroup.drawer);
    final empty = PageGroup.maxDrawer - items.length;
    Widget fixed(String label, IconData icon) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: palette.muted),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: palette.muted, fontSize: 12)),
        ],
      ),
    );
    return Container(
      width: _drawerWidth,
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(right: BorderSide(color: palette.border)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: _drop(
        PageGroup.drawer,
        (hot, bad) => _zoneBox(
          hot: hot,
          bad: bad,
          padding: const EdgeInsets.fromLTRB(6, 12, 6, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 6),
                child: Text(
                  '좌측 탭 ${items.length}/${PageGroup.maxDrawer}',
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              for (final p in items)
                _item(
                  p,
                  (hot) => Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          pageIconOf(p.icon).outlined,
                          size: 16,
                          color: palette.brand,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            p.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              for (var i = 0; i < empty; i++)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: palette.border),
                  ),
                ),
              const Divider(height: 20),
              fixed('내 활동', AppIcons.user),
              fixed('교회 탐색', AppIcons.compass),
            ],
          ),
        ),
      ),
    );
  }

  /// 하단 탭의 양옆 버튼 자리 하나.
  Widget _slot(PageGroup g, String hint) {
    final palette = context.palette;
    final page = _in(g).firstOrNull;
    return _drop(
      g,
      (hot, bad) => _zoneBox(
        hot: hot,
        bad: bad,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: SizedBox(
          height: 44,
          child: page == null
              ? Center(
                  child: Text(
                    hint,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: palette.muted, fontSize: 10),
                  ),
                )
              : _item(
                  page,
                  (hot) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        pageIconOf(page.icon).outlined,
                        size: 18,
                        color: palette.brand,
                      ),
                      Text(
                        page.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _phone() {
    final palette = context.palette;
    return SizedBox(
      width: _phoneWidth,
      height: _phoneHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: palette.bg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: palette.border, width: 2),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  SizedBox(
                    height: 44,
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Icon(
                          AppIcons.sidebarSimple,
                          size: 20,
                          color: palette.muted,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(left: _drawerWidth + 4),
                      child: _homeZone(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    child: Container(
                      height: 62,
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: palette.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: _slot(PageGroup.left, '왼쪽 버튼')),
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: palette.brand,
                            child: Icon(
                              AppIcons.house,
                              size: 22,
                              color: palette.onBrand,
                            ),
                          ),
                          Expanded(child: _slot(PageGroup.right, '오른쪽 버튼')),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // 실제 앱에서는 서랍이 하단 탭까지 덮지만, 여기서는 두 자리를 모두 끌어 놓을 수 있게 하단 탭 위까지만 연다.
              Positioned(left: 0, top: 0, bottom: 80, child: _drawer()),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('배치 설정', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Center(child: _phone()),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_error!, style: TextStyle(color: error)),
          ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _saving || !_changed ? null : _save,
              child: Text(_saving ? '저장 중' : '저장'),
            ),
          ],
        ),
      ],
    );
  }
}

/// 끄는 동안 손가락 아래에 따라다니는 페이지 표시.
class _Chip extends StatelessWidget {
  const _Chip({required this.page});

  final PageConfig page;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.brand),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(pageIconOf(page.icon).outlined, size: 16, color: palette.brand),
          const SizedBox(width: 6),
          Text(
            page.title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
