import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/layout/confirm_dialog.dart';
import '../../../core/layout/app_dialog.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/member.dart';
import '../../../data/models/page_layout.dart';
import '../view_model/church_pages_view_model.dart';
import 'design_gallery.dart';
import 'page_icons.dart';

/// 페이지 편집: 교회 메뉴의 페이지를 목록으로 보여주고 추가 · 삭제 · 순서 변경을 한다.
/// 순서는 왼쪽 손잡이를 잡고 끌어서 바꾼다 (더 보기 메뉴의 위로/아래로도 된다).
/// 페이지는 최소 하나는 남아 있어야 한다. "수정"을 누르면 그 페이지의 구성을 고치는 화면으로 간다.
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
              const PageTitle(title: '페이지 편집'),
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
              for (final group in PageGroup.values) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    group.sectionTitle,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                _ReorderablePages(
                  pages: _of(group),
                  busy: vm.busy,
                  canDelete: pages.length > 1,
                  group: group,
                  onEdit: (p) =>
                      context.push(Routes.pageEdit(me.churchId, p.id)),
                  onReorder: (next) => _save(vm, group, next),
                  onMove: (i, d) => _move(vm, group, i, d),
                  onMoveTo: (p, to) => _changeGroup(vm, p, to),
                  onDelete: (p) => _delete(context, vm, p),
                ),
                const SizedBox(height: 20),
              ],
              // 내 활동은 직접 고치지 않는다. 기도 · 말씀 페이지 구성에 따라 자동으로 정해진다.
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '내 활동',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              _MyActivityPreview(activities: MyActivity.from(pages)),
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
      label: const Text('페이지 추가'),
    );
    final reset = OutlinedButton.icon(
      onPressed: vm.busy ? null : () => _resetToDefaults(context, vm),
      icon: const Icon(Icons.restart_alt, size: 18),
      label: const Text('기본 구성으로 되돌리기'),
    );
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        SizedBox(width: narrow ? double.infinity : null, child: button),
        SizedBox(width: narrow ? double.infinity : null, child: reset),
      ],
    );
  }

  /// 지금 페이지들을 모두 지우고 기본 구성(홈: 공지사항 · 일정 / 말씀 / 기도)으로 되돌린다.
  Future<void> _resetToDefaults(
    BuildContext context,
    PageLayoutEditorViewModel vm,
  ) async {
    final ok = await confirmChange(
      context,
      title: '기본 구성으로 되돌리기',
      body: '지금 만든 페이지와 레이아웃이 모두 사라지고 기본 구성으로 바뀌어요. 되돌릴 수 없어요.',
      confirmLabel: '되돌리기',
    );
    if (!ok) return;
    final keep = {for (final d in PageConfig.defaults) d.id};
    await vm.save(PageConfig.defaults, [
      for (final p in pages)
        if (!keep.contains(p.id)) p.id,
    ]);
  }

  /// 새 페이지를 만든다. 템플릿(목적)을 고르고 디자인을 고르면 편집 화면이 열리고,
  /// 저장 버튼을 눌러야 비로소 교회에 만들어진다 (저장하지 않고 나가면 만들어지지 않는다).
  Future<void> _add(BuildContext context, PageLayoutEditorViewModel vm) async {
    final router = GoRouter.of(context);
    final template = await showAppDialog<_Template>(
      context,
      maxWidth: 520,
      child: const _TemplateDialog(),
    );
    if (template == null || !context.mounted) return;

    final id = 'p${DateTime.now().millisecondsSinceEpoch}';
    final draft = await _newPage(context, id, template);
    if (draft == null) return;
    router.push(Routes.pageEdit(me.churchId, id), extra: draft);
  }

  /// 템플릿의 구조에서 디자인을 골라 새 페이지(저장 전)를 만든다.
  /// 디자인이 하나뿐인 구조는 고르기를 건너뛰고, 기타는 모든 구조 중에서 고른다.
  Future<PageConfig?> _newPage(
    BuildContext context,
    String id,
    _Template template,
  ) async {
    final DesignChoice? choice;
    final only = template.type;
    if (only != null && only.variants.length == 1) {
      choice = DesignChoice(only, only.variants.first.id);
    } else {
      choice = await showDesignGallery(context, only: only);
    }
    if (choice == null) return null;
    final type = choice.type;
    final source = type.sources[template.sourceIndex];
    return PageConfig(
      id: id,
      title: template.pageTitle ?? type.label,
      icon: template.icon,
      // 기타는 고른 구조에 맞는 그룹(기도 · 말씀 · 홈)에 둔다.
      group: template.type == null
          ? PageGroup.defaultFor(type)
          : template.group,
      layout: BlockConfig(
        id: 'b${DateTime.now().millisecondsSinceEpoch}',
        type: type,
        variant: choice.variant,
        source: source,
        title: source.label,
      ),
    );
  }

  /// [group]에 속한 페이지들 (저장된 순서대로).
  List<PageConfig> _of(PageGroup group) => [
    for (final p in pages)
      if (p.group == group) p,
  ];

  /// [group] 쪽의 순서를 [next]로 바꿔 저장한다. 저장 순서는 홈, 기도, 말씀 순이다.
  Future<void> _save(
    PageLayoutEditorViewModel vm,
    PageGroup group,
    List<PageConfig> next,
  ) => vm.save([
    for (final g in PageGroup.values) ...(g == group ? next : _of(g)),
  ], const []);

  Future<void> _move(
    PageLayoutEditorViewModel vm,
    PageGroup group,
    int index,
    int delta,
  ) async {
    final list = _of(group);
    final j = index + delta;
    if (j < 0 || j >= list.length) return;
    list.insert(j, list.removeAt(index));
    await _save(vm, group, list);
  }

  /// 페이지를 [to] 그룹의 맨 아래로 옮긴다.
  Future<void> _changeGroup(
    PageLayoutEditorViewModel vm,
    PageConfig page,
    PageGroup to,
  ) => vm.save([
    for (final g in PageGroup.values) ...[
      for (final p in _of(g))
        if (p.id != page.id) p,
      if (g == to) page.copyWith(group: to),
    ],
  ], const []);

  Future<void> _delete(
    BuildContext context,
    PageLayoutEditorViewModel vm,
    PageConfig page,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('페이지 삭제'),
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
    required this.canDelete,
    required this.group,
    required this.onEdit,
    required this.onReorder,
    required this.onMove,
    required this.onMoveTo,
    required this.onDelete,
  });

  final List<PageConfig> pages;
  final bool busy;

  /// 페이지가 둘 이상일 때만 지울 수 있다 (전체 기준).
  final bool canDelete;
  final PageGroup group;
  final void Function(PageConfig) onEdit;
  final void Function(List<PageConfig>) onReorder;
  final void Function(int index, int delta) onMove;
  final void Function(PageConfig, PageGroup) onMoveTo;
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
      // 배경색이 있는 바깥 틀 안에서도 ListTile의 눌림 효과가 보이도록 투명한 Material을 둔다.
      child: Material(
        type: MaterialType.transparency,
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
                canDelete: widget.canDelete,
                group: widget.group,
                busy: widget.busy,
                onEdit: () => widget.onEdit(page),
                onMove: (d) => widget.onMove(i, d),
                onMoveTo: (to) => widget.onMoveTo(page, to),
                onDelete: () => widget.onDelete(page),
              ),
            );
          },
        ),
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
    required this.group,
    required this.onEdit,
    required this.onMove,
    required this.onMoveTo,
    required this.onDelete,
  });

  final int index;
  final PageConfig page;
  final bool first;
  final bool last;
  final bool canDelete;
  final bool busy;
  final PageGroup group;
  final VoidCallback onEdit;
  final ValueChanged<int> onMove;
  final ValueChanged<PageGroup> onMoveTo;
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
      subtitle: Text(page.layout == null ? '레이아웃 없음' : page.layout!.type.label),
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
              for (final g in PageGroup.values)
                if (g != group)
                  PopupMenuItem(
                    value: () => onMoveTo(g),
                    child: Text('${g.label}(으)로 옮기기'),
                  ),
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

/// 새 페이지의 템플릿: 교회가 하려는 일(목적)에 맞춰 구조와 자료, 페이지 이름·아이콘이 정해진다.
/// 새 주제가 생기면 [_templates]에 넣지 않고 우선 [other](기타)로 만든다.
class _Template {
  const _Template({
    required this.label,
    required this.icon,
    this.type,
    this.pageTitle,
    this.sourceIndex = 0,
    this.group = PageGroup.home,
  });

  final String label;

  /// 페이지 메뉴 아이콘 이름 (`pageIcons`의 키).
  final String icon;

  /// 쓸 구조. null이면 기타: 모든 구조 중에서 고른다.
  final BlockType? type;

  /// 새 페이지의 이름. null이면 구조 이름.
  final String? pageTitle;

  /// 구조가 보여줄 수 있는 자료 중 몇 번째를 쓰는지 (게시판: 0 공지, 1 사진첩).
  final int sourceIndex;

  /// 새 페이지가 속할 그룹 (홈 · 기도 · 말씀).
  final PageGroup group;
}

const _templates = [
  _Template(
    label: '공지·소식',
    icon: 'campaign',
    type: BlockType.board,
    pageTitle: '공지사항',
  ),
  _Template(
    label: '행사·수련회 사진',
    icon: 'photo',
    type: BlockType.gallery,
    pageTitle: '사진첩',
  ),
  _Template(
    label: '설교·찬양 영상',
    icon: 'video',
    type: BlockType.video,
    pageTitle: '설교영상',
  ),
  _Template(
    label: '예배·행사 일정',
    icon: 'event',
    type: BlockType.schedule,
    pageTitle: '일정',
  ),
  _Template(
    label: '말씀 묵상',
    icon: 'book',
    type: BlockType.devotion,
    pageTitle: '말씀묵상',
    group: PageGroup.word,
  ),
  _Template(
    label: '기도 요청',
    icon: 'favorite',
    type: BlockType.prayer,
    pageTitle: '기도 요청',
    group: PageGroup.prayer,
  ),
  _Template(
    label: '홍보자료',
    icon: 'star',
    type: BlockType.board,
    pageTitle: '홍보자료',
    sourceIndex: 1,
  ),
];

/// 어느 템플릿에도 맞지 않는 새 주제.
const _other = _Template(label: '기타', icon: 'star');

class _TemplateDialog extends StatelessWidget {
  const _TemplateDialog();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('새 페이지 만들기', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final t in [..._templates, _other]) ...[
                  _Choice(
                    icon: pageIconOf(t.icon).outlined,
                    title: t.label,
                    onTap: () => Navigator.pop(context, t),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({required this.icon, required this.title, required this.onTap});

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final radius = BorderRadius.circular(AppRadius.card);
    return InkWell(
      borderRadius: radius,
      onTap: onTap,
      child: Ink(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: palette.surface,
          border: Border.all(color: palette.border),
          borderRadius: radius,
        ),
        child: Row(
          children: [
            Icon(icon, color: palette.brand),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: palette.muted),
          ],
        ),
      ),
    );
  }
}

/// 내 활동 미리보기: 기도 · 말씀 페이지 구성에 따라 자동으로 정해지는 항목들 (고칠 수 없다).
class _MyActivityPreview extends StatelessWidget {
  const _MyActivityPreview({required this.activities});

  final List<MyActivity> activities;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      padding: const EdgeInsets.all(16),
      child: activities.isEmpty
          ? Text('없음', style: TextStyle(color: palette.muted))
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in activities)
                  Chip(
                    avatar: Icon(Icons.check, size: 16, color: palette.brand),
                    label: Text(a.label),
                  ),
              ],
            ),
    );
  }
}
