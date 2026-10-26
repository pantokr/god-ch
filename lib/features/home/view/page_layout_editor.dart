import 'package:flutter/material.dart';

import '../../../core/back_navigation.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/member.dart';
import '../../../data/models/page_layout.dart';
import '../view_model/church_pages_view_model.dart';
import 'church_page_view.dart';
import 'design_gallery.dart';
import 'content_widgets.dart';
import 'page_icons.dart';

/// 한 페이지의 구성 편집: 이름·아이콘을 고치고, 구조(캐러셀 · 게시판 · 일정 · 메신저)를 위아래로 쌓고
/// 구조마다 디자인을 고른다. 고친 내용은 "저장"을 눌러야 교회 모두에게 반영된다.
/// 페이지 목록(추가·삭제·순서)은 [PageListPage]에서 다룬다.
class PageLayoutEditor extends StatefulWidget {
  const PageLayoutEditor({
    super.key,
    required this.me,
    required this.pages,
    required this.pageId,
  });

  final Member me;

  /// 교회의 모든 페이지. 저장할 때 이 중 [pageId]의 페이지만 고쳐서 함께 저장한다.
  final List<PageConfig> pages;
  final String pageId;

  @override
  State<PageLayoutEditor> createState() => _PageLayoutEditorState();
}

class _PageLayoutEditorState extends State<PageLayoutEditor> {
  late final List<PageConfig> _pages = List.of(widget.pages);
  late final int _index = _pages.indexWhere((p) => p.id == widget.pageId);
  bool _dirty = false;

  int _serial = 0;

  PageConfig get _page => _pages[_index];

  String _newId(String prefix) =>
      '$prefix${DateTime.now().millisecondsSinceEpoch}${_serial++}';

  void _change(VoidCallback f) => setState(() {
    f();
    _dirty = true;
  });

  void _setPage(PageConfig p) => _change(() => _pages[_index] = p);

  void _setBlock(int i, BlockConfig b) {
    final blocks = List.of(_page.blocks)..[i] = b;
    _setPage(_page.copyWith(blocks: blocks));
  }

  void _moveBlock(int i, int delta) {
    final j = i + delta;
    if (j < 0 || j >= _page.blocks.length) return;
    final blocks = List.of(_page.blocks);
    blocks.insert(j, blocks.removeAt(i));
    _setPage(_page.copyWith(blocks: blocks));
  }

  void _removeBlock(int i) {
    final blocks = List.of(_page.blocks)..removeAt(i);
    _setPage(_page.copyWith(blocks: blocks));
  }

  /// 디자인 갤러리에서 실제 모습을 보고 고른 구조를 [at] 자리에 끼워 넣는다.
  Future<void> _addBlock(int at) async {
    final choice = await showDesignGallery(context);
    if (choice == null) return;
    final type = choice.type;
    final source = type.sources.first;
    final blocks = List.of(_page.blocks)
      ..insert(
        at,
        BlockConfig(
          id: _newId('b'),
          type: type,
          variant: choice.variant,
          source: source,
          title: type == BlockType.messenger ? '함께 나누는 기도제목' : source.label,
          limit: type == BlockType.messenger ? 20 : 5,
        ),
      );
    _setPage(_page.copyWith(blocks: blocks));
  }

  Future<void> _save(PageLayoutEditorViewModel vm) async {
    final messenger = ScaffoldMessenger.of(context);
    if (await vm.save(_pages, const [])) {
      setState(() => _dirty = false);
      messenger.showSnackBar(const SnackBar(content: Text('페이지 구성을 저장했어요.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    if (_index < 0) {
      return const EmptyHint('없는 페이지예요. 페이지 목록으로 돌아가 주세요.');
    }
    return ViewModelBuilder<PageLayoutEditorViewModel>(
      create: (context) => PageLayoutEditorViewModel(
        AppScope.read(context).pageLayouts,
        widget.me.churchId,
      ),
      builder: (context, vm) {
        final pad = pagePadding(context);
        final narrow = MediaQuery.sizeOf(context).width < kNarrow;
        final editor = LayoutBuilder(
          // 스크롤 영역은 전체 폭이고, 안쪽 여백으로 글 칸을 가운데 [kContentWidth]에 맞춘다.
          builder: (context, box) => SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              pad + ((box.maxWidth - kContentWidth) / 2).clamp(0, 1e9),
              narrow ? 8 : 20,
              pad + ((box.maxWidth - kContentWidth) / 2).clamp(0, 1e9),
              20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: '페이지 목록',
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () =>
                          context.goBack(Routes.pageList(widget.me.churchId)),
                    ),
                    Expanded(
                      child: Text(
                        '${_page.title} 편집',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          fullscreenDialog: true,
                          builder: (_) =>
                              _PagePreview(page: _page, me: widget.me),
                        ),
                      ),
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('미리보기'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 20),
                // 메뉴 개요 구역만 배경색을 달리해 페이지 구성과 구분한다.
                Container(
                  padding: const EdgeInsets.all(16),
                  // 비비드한 포인트색 면에 그림자를 깔고, 모서리는 각지게 둔다.
                  decoration: BoxDecoration(
                    color: palette.brand,
                    boxShadow: [
                      BoxShadow(
                        color: palette.brand.withValues(alpha: 0.45),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                      ...AppShadow.soft(context),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _SectionHeader(
                        icon: Icons.menu_open_outlined,
                        title: '메뉴 개요',
                        onColor: true,
                      ),
                      _pageCard(context),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 20),
                const _SectionHeader(
                  icon: Icons.view_agenda_outlined,
                  title: '페이지 구성',
                ),
                // 구조 사이사이의 "+"를 눌러 원하는 위치에 새 구조를 끼워 넣는다.
                _InsertSlot(
                  onTap: _page.blocks.length >= 20 ? null : () => _addBlock(0),
                  label: _page.blocks.isEmpty ? '구조 추가' : '맨 위에 구조 추가',
                ),
                for (var i = 0; i < _page.blocks.length; i++) ...[
                  _BlockEditor(
                    key: ValueKey(_page.blocks[i].id),
                    block: _page.blocks[i],
                    first: i == 0,
                    last: i == _page.blocks.length - 1,
                    onChanged: (b) => _setBlock(i, b),
                    onMove: (d) => _moveBlock(i, d),
                    onRemove: () => _removeBlock(i),
                  ),
                  _InsertSlot(
                    onTap: _page.blocks.length >= 20
                        ? null
                        : () => _addBlock(i + 1),
                    label: i == _page.blocks.length - 1
                        ? '맨 아래에 구조 추가'
                        : '여기에 구조 추가',
                  ),
                ],
                const SizedBox(height: 24),
                if (vm.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      vm.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                FilledButton.icon(
                  onPressed: vm.busy || !_dirty ? null : () => _save(vm),
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(_dirty ? '저장' : '저장됨'),
                ),
              ],
            ),
          ),
        );
        return editor;
      },
    );
  }

  Widget _pageCard(BuildContext context) {
    final page = _page;
    // 바깥 구역의 색 면이 곧 배경이다 (안쪽에 따로 카드를 깔지 않는다).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          key: ValueKey('title/${page.id}'),
          initialValue: page.title,
          maxLength: 30,
          buildCounter: noCounter,
          decoration: const InputDecoration(labelText: '페이지 이름'),
          onChanged: (v) => _setPage(page.copyWith(title: v)),
        ),
        const SizedBox(height: 20),
        Text(
          '메뉴 아이콘',
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(color: context.palette.onBrand),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: [
            for (final e in pageIcons.entries)
              ChoiceChip(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                materialTapTargetSize: MaterialTapTargetSize.padded,
                avatar: Icon(e.value.outlined, size: 18),
                label: Text(e.value.label),
                selected: page.icon == e.key,
                onSelected: (_) => _setPage(page.copyWith(icon: e.key)),
              ),
          ],
        ),
      ],
    );
  }
}

/// 고치는 중인 페이지(저장 전)를 실제 화면 폭 그대로, 실제 자료로 보여주는 전체 화면 미리보기.
/// 눌러도 이동하지 않는다.
Widget? noCounter(
  BuildContext context, {
  required int currentLength,
  required bool isFocused,
  required int? maxLength,
}) => null;

class _PagePreview extends StatelessWidget {
  const _PagePreview({required this.page, required this.me});

  final PageConfig page;
  final Member me;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('미리보기 · ${page.title}')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: AbsorbPointer(
            child: ChurchPageBody(page: page, me: me),
          ),
        ),
      ),
    );
  }
}

/// 편집 화면의 큰 구역(메뉴 개요 · 페이지 구성)을 나누는 제목.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    this.onColor = false,
  });

  final IconData icon;
  final String title;

  /// 포인트색 면 위에 놓일 때 true: 글자와 아이콘을 [AppPalette.onBrand]로 쓴다.
  final bool onColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final fg = onColor ? palette.onBrand : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: fg),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: fg),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 구조 사이에 끼워 넣는 "+" 줄.
class _InsertSlot extends StatelessWidget {
  const _InsertSlot({required this.onTap, required this.label});

  final VoidCallback? onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Center(
        child: TextButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.add_circle_outline, size: 18),
          label: Text(label),
        ),
      ),
    );
  }
}

/// 구조 한 칸의 설정: 제목 · 구조 · 자료 · 디자인 · 개수. 모두 세로로 쌓여 좁은 화면에서도 넘치지 않는다.
class _BlockEditor extends StatelessWidget {
  const _BlockEditor({
    super.key,
    required this.block,
    required this.first,
    required this.last,
    required this.onChanged,
    required this.onMove,
    required this.onRemove,
  });

  final BlockConfig block;
  final bool first;
  final bool last;
  final ValueChanged<BlockConfig> onChanged;
  final ValueChanged<int> onMove;
  final VoidCallback onRemove;

  Future<void> _changeDesign(BuildContext context) async {
    final c = await showDesignGallery(
      context,
      only: block.type,
      current: DesignChoice(block.type, block.variant),
    );
    if (c != null) onChanged(block.copyWith(type: c.type, variant: c.variant));
  }

  /// 분류(구조)를 바꾼다. 지금 보여주던 자료를 새 분류도 쓸 수 있으면 그대로 두고, 아니면 그 분류의 기본 자료로 맞춘다.
  /// 구역 제목은 바꾸지 않는다.
  void _changeCategory(String typeId) {
    final t = BlockType.fromId(typeId);
    final s = t.sources.firstWhere(
      (x) => x.id == block.source.id,
      orElse: () => t.sources.first,
    );
    onChanged(
      block.copyWith(
        type: t,
        source: s,
        limit: t == BlockType.messenger
            ? 20
            : block.type == BlockType.messenger
            ? 5
            : block.limit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final type = block.type;
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Spacer(),
                IconButton(
                  tooltip: '위로',
                  onPressed: first ? null : () => onMove(-1),
                  icon: const Icon(Icons.arrow_upward, size: 20),
                ),
                IconButton(
                  tooltip: '아래로',
                  onPressed: last ? null : () => onMove(1),
                  icon: const Icon(Icons.arrow_downward, size: 20),
                ),
                IconButton(
                  tooltip: '삭제',
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline, size: 20),
                ),
              ],
            ),
            // 구역에서 정하는 것은 분류(고르기)와 제목(쓰기) 둘뿐이다. 같은 모양의 칸이지만 이름표와 아이콘이 다르다.
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 8, 16),
              child: LayoutBuilder(
                builder: (context, box) {
                  final category = DropdownButtonFormField<String>(
                    initialValue: type.id,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(AppRadius.control),
                    decoration: const InputDecoration(
                      labelText: '분류',
                      prefixIcon: Icon(Icons.folder_open_outlined),
                    ),
                    items: [
                      for (final t in BlockType.values)
                        DropdownMenuItem(value: t.id, child: Text(t.label)),
                    ],
                    onChanged: (v) {
                      if (v != null) _changeCategory(v);
                    },
                  );
                  final title = TextFormField(
                    initialValue: block.title,
                    maxLength: 30,
                    buildCounter: noCounter,
                    decoration: const InputDecoration(
                      labelText: '제목',
                      prefixIcon: Icon(Icons.edit_outlined),
                    ),
                    onChanged: (v) => onChanged(block.copyWith(title: v)),
                  );
                  if (box.maxWidth >= 560) {
                    return Row(
                      children: [
                        Expanded(flex: 2, child: category),
                        const SizedBox(width: 12),
                        Expanded(flex: 3, child: title),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [category, const SizedBox(height: 12), title],
                  );
                },
              ),
            ),
            // 지금 쓰는 디자인의 실제 모습. 누르면 갤러리에서 같은 구조의 다른 디자인으로 바꾼다.
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      InkWell(
                        onTap: () => _changeDesign(context),
                        child: DesignThumbnail(
                          type: type,
                          variant: block.variant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        onPressed: () => _changeDesign(context),
                        icon: const Icon(Icons.palette_outlined, size: 18),
                        label: const Text('디자인 바꾸기'),
                      ),
                    ],
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
