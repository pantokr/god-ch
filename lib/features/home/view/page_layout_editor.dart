import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  /// 좁은 화면에서 편집 대신 미리보기를 보는 중인가 (넓은 화면은 옆에 같이 보여준다).
  bool _showPreview = false;
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
        final editor = SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: '페이지 목록',
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () =>
                        context.go(Routes.pageList(widget.me.churchId)),
                  ),
                  Expanded(
                    child: Text(
                      '${_page.title} 편집',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              Text(
                '이름과 아이콘을 고치고, 구조를 위아래로 쌓아 디자인을 골라요.',
                style: TextStyle(color: palette.muted),
              ),
              const SizedBox(height: 16),
              _pageCard(context),
              const SizedBox(height: 12),
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
        );
        final preview = _PagePreview(page: _page, me: widget.me);
        if (MediaQuery.sizeOf(context).width >= kNarrow) {
          // 넓은 화면: 편집과 미리보기를 나란히 보여준다. 각자 따로 스크롤된다.
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: editor),
              const SizedBox(width: 20),
              Expanded(flex: 4, child: preview),
            ],
          );
        }
        // 좁은 화면: 위의 스위치로 편집과 미리보기를 오간다.
        return Column(
          children: [
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.edit_outlined, size: 18),
                    label: Text('편집'),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.visibility_outlined, size: 18),
                    label: Text('미리보기'),
                  ),
                ],
                selected: {_showPreview},
                onSelectionChanged: (s) =>
                    setState(() => _showPreview = s.first),
              ),
            ),
            Expanded(child: _showPreview ? preview : editor),
          ],
        );
      },
    );
  }

  Widget _pageCard(BuildContext context) {
    final page = _page;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: ValueKey('title/${page.id}'),
              initialValue: page.title,
              maxLength: 30,
              decoration: const InputDecoration(labelText: '페이지 이름 (메뉴에 보여요)'),
              onChanged: (v) => _setPage(page.copyWith(title: v)),
            ),
            const SizedBox(height: 4),
            Text('메뉴 아이콘', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in pageIcons.entries)
                  ChoiceChip(
                    avatar: Icon(e.value.outlined, size: 18),
                    label: Text(e.value.label),
                    selected: page.icon == e.key,
                    onSelected: (_) => _setPage(page.copyWith(icon: e.key)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 고치는 중인 페이지(저장 전)를 실제 자료로 그려 보여주는 미리보기.
/// 눌러도 이동하지 않는다.
class _PagePreview extends StatelessWidget {
  const _PagePreview({required this.page, required this.me});

  final PageConfig page;
  final Member me;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.visibility_outlined, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '미리보기 · ${page.title}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '저장하기 전 모습이에요. 실제 등록된 자료로 보여줘요.',
            style: TextStyle(color: palette.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: palette.bg,
              border: Border.all(color: palette.border),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AbsorbPointer(
              child: ChurchPageBody(page: page, me: me),
            ),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.add_circle_outline, size: 18),
        label: Text(label),
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

  @override
  Widget build(BuildContext context) {
    final type = block.type;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${type.label} · ${block.variantInfo.label}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
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
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    initialValue: block.title,
                    maxLength: 30,
                    decoration: const InputDecoration(
                      labelText: '구역 제목 (비우면 제목 없이)',
                    ),
                    onChanged: (v) => onChanged(block.copyWith(title: v)),
                  ),
                  const SizedBox(height: 4),
                  // 지금 쓰는 디자인의 실제 모습. 누르면 갤러리에서 다른 디자인으로 바꾼다.
                  InkWell(
                    onTap: () => _changeDesign(context),
                    child: DesignThumbnail(
                      type: type,
                      variant: block.variant,
                      height: 130,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _changeDesign(context),
                      icon: const Icon(Icons.palette_outlined, size: 18),
                      label: const Text('디자인 바꾸기'),
                    ),
                  ),
                  if (type.sources.length > 1) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: block.source.id,
                      decoration: const InputDecoration(labelText: '보여줄 자료'),
                      items: [
                        for (final s in type.sources)
                          DropdownMenuItem(value: s.id, child: Text(s.label)),
                      ],
                      onChanged: (id) {
                        if (id == null) return;
                        onChanged(
                          block.copyWith(
                            source: type.sources.firstWhere((s) => s.id == id),
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (type != BlockType.schedule) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          '보여줄 개수  ${block.limit}개',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        Expanded(
                          child: Slider(
                            value: block.limit.toDouble(),
                            min: 1,
                            max: 20,
                            divisions: 19,
                            label: '${block.limit}개',
                            onChanged: (v) =>
                                onChanged(block.copyWith(limit: v.round())),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
