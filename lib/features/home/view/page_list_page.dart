import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/member.dart';
import '../../../data/models/page_layout.dart';
import '../view_model/church_pages_view_model.dart';
import 'page_icons.dart';

/// 페이지 편집: 교회 메뉴의 대분류(페이지)를 목록으로 보여주고 추가 · 삭제 · 순서 변경을 한다.
/// 순서는 왼쪽 손잡이를 잡고 끌어서 바꾼다 (더 보기 메뉴의 위로/아래로도 된다).
/// 대분류는 최소 하나는 남아 있어야 한다. "수정"을 누르면 그 페이지의 구성을 고치는 화면으로 간다.
/// 공지·일정 같은 글 자체는 "콘텐츠 관리"(교회 운영자)에서 따로 고친다.
class PageListPage extends StatelessWidget {
  const PageListPage({super.key, required this.me, required this.pages});

  final Member me;

  /// 지금 저장된 페이지들 (아직 편집한 적 없으면 기본 구성).
  final List<PageConfig> pages;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < kNarrow;
    return ViewModelBuilder<PageLayoutEditorViewModel>(
      create: (context) => PageLayoutEditorViewModel(
        AppScope.read(context).pageLayouts,
        me.churchId,
      ),
      builder: (context, vm) => SingleChildScrollView(
        child: PageFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageTitle(
                title: '페이지 편집',
                subtitle: '교회 메뉴의 대분류예요. 수정을 누르면 그 페이지의 구성을 고칠 수 있어요.',
              ),
              _addButton(context, vm, narrow),
              if (vm.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    vm.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _ReorderablePages(
                pages: pages,
                busy: vm.busy,
                onEdit: (p) => context.go(Routes.pageEdit(me.churchId, p.id)),
                onReorder: (next) => vm.save(next, const []),
                onMove: (i, d) => _move(context, vm, i, d),
                onDelete: (p) => _delete(context, vm, p),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addButton(
    BuildContext context,
    PageLayoutEditorViewModel vm,
    bool narrow,
  ) {
    final button = FilledButton.icon(
      onPressed: vm.busy || pages.length >= 12 ? null : () => _add(context, vm),
      icon: const Icon(Icons.add, size: 18),
      label: const Text('대분류 추가'),
    );
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(width: narrow ? double.infinity : null, child: button),
    );
  }

  /// 새 대분류를 만들어 저장하고, 바로 그 페이지의 구성 편집으로 이동한다.
  Future<void> _add(BuildContext context, PageLayoutEditorViewModel vm) async {
    final router = GoRouter.of(context);
    final id = 'p${DateTime.now().millisecondsSinceEpoch}';
    final ok = await vm.save([
      ...pages,
      PageConfig(id: id, title: '새 페이지', icon: 'star'),
    ], const []);
    if (ok) router.go(Routes.pageEdit(me.churchId, id));
  }

  Future<void> _move(
    BuildContext context,
    PageLayoutEditorViewModel vm,
    int index,
    int delta,
  ) async {
    final j = index + delta;
    if (j < 0 || j >= pages.length) return;
    final next = List.of(pages);
    next.insert(j, next.removeAt(index));
    await vm.save(next, const []);
  }

  Future<void> _delete(
    BuildContext context,
    PageLayoutEditorViewModel vm,
    PageConfig page,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('대분류 삭제'),
        content: Text('"${page.title}" 페이지를 삭제할까요? 메뉴에서 사라지고 되돌릴 수 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await vm.save(
      [
        for (final p in pages)
          if (p.id != page.id) p,
      ],
      [page.id],
    );
  }
}

/// 끌어서 순서를 바꾸는 페이지 목록. 놓는 즉시 화면의 순서를 바꾸고 저장은 뒤따른다
/// (저장된 순서가 돌아오기 전에 목록이 제자리로 튀지 않게 하려고 순서를 따로 들고 있는다).
class _ReorderablePages extends StatefulWidget {
  const _ReorderablePages({
    required this.pages,
    required this.busy,
    required this.onEdit,
    required this.onReorder,
    required this.onMove,
    required this.onDelete,
  });

  final List<PageConfig> pages;
  final bool busy;
  final void Function(PageConfig) onEdit;
  final void Function(List<PageConfig>) onReorder;
  final void Function(int index, int delta) onMove;
  final void Function(PageConfig) onDelete;

  @override
  State<_ReorderablePages> createState() => _ReorderablePagesState();
}

class _ReorderablePagesState extends State<_ReorderablePages> {
  late List<PageConfig> _items = List.of(widget.pages);

  @override
  void didUpdateWidget(_ReorderablePages old) {
    super.didUpdateWidget(old);
    // 저장된 구성이 바뀌어 오면(순서 저장, 추가, 삭제) 그것을 따른다.
    _items = List.of(widget.pages);
  }

  void _reorder(int from, int to) {
    // onReorderItem의 to는 이미 항목을 뺀 뒤의 자리다.
    if (from == to) return;
    setState(() => _items.insert(to, _items.removeAt(from)));
    widget.onReorder(List.of(_items));
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      clipBehavior: Clip.antiAlias,
      child: ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        // 손잡이로만 끌 수 있게 기본 손잡이는 끈다.
        buildDefaultDragHandles: false,
        itemCount: _items.length,
        onReorderItem: widget.busy ? (_, _) {} : _reorder,
        proxyDecorator: (child, _, _) =>
            Material(elevation: 4, color: palette.surface, child: child),
        itemBuilder: (context, i) {
          final page = _items[i];
          return Container(
            key: ValueKey(page.id),
            decoration: BoxDecoration(
              border: i == 0
                  ? null
                  : Border(top: BorderSide(color: palette.border)),
            ),
            child: _PageRow(
              index: i,
              page: page,
              first: i == 0,
              last: i == _items.length - 1,
              canDelete: _items.length > 1,
              busy: widget.busy,
              onEdit: () => widget.onEdit(page),
              onMove: (d) => widget.onMove(i, d),
              onDelete: () => widget.onDelete(page),
            ),
          );
        },
      ),
    );
  }
}

class _PageRow extends StatelessWidget {
  const _PageRow({
    required this.index,
    required this.page,
    required this.first,
    required this.last,
    required this.canDelete,
    required this.busy,
    required this.onEdit,
    required this.onMove,
    required this.onDelete,
  });

  final int index;
  final PageConfig page;
  final bool first;
  final bool last;
  final bool canDelete;
  final bool busy;
  final VoidCallback onEdit;
  final ValueChanged<int> onMove;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onEdit,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 이 손잡이를 잡고 위아래로 끌어 순서를 바꾼다.
          ReorderableDragStartListener(
            index: index,
            child: MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: Tooltip(
                message: '끌어서 순서 바꾸기',
                child: Icon(Icons.drag_indicator, color: context.palette.muted),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(pageIconOf(page.icon).outlined),
        ],
      ),
      title: Text(page.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        page.blocks.isEmpty ? '구조 없음' : '구조 ${page.blocks.length}개',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: '수정',
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: onEdit,
          ),
          PopupMenuButton<VoidCallback>(
            tooltip: '더 보기',
            enabled: !busy,
            onSelected: (a) => a(),
            itemBuilder: (context) => [
              if (!first)
                PopupMenuItem(value: () => onMove(-1), child: const Text('위로')),
              if (!last)
                PopupMenuItem(value: () => onMove(1), child: const Text('아래로')),
              PopupMenuItem(
                value: onDelete,
                enabled: canDelete,
                child: Text(canDelete ? '삭제' : '삭제 (최소 1개는 남겨야 해요)'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
