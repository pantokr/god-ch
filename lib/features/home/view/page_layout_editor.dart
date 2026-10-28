import '../../../core/icons.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/back_navigation.dart';
import '../../../core/layout/app_dialog.dart';
import '../../../core/layout/confirm_dialog.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/block_style.dart';
import '../../../data/models/church_content.dart';
import '../../../data/models/member.dart';
import '../../../data/models/page_layout.dart';
import '../../../data/models/prayer_settings.dart';
import '../../prayers/view/prayer_settings_panel.dart';
import '../view_model/church_pages_view_model.dart';
import 'church_page_view.dart';
import 'design_gallery.dart';
import 'content_widgets.dart';
import 'page_icons.dart';
import '../../../core/widgets/app_inputs.dart';

/// 한 페이지의 편집. 1단계는 이름 · 위치 · 아이콘(새 페이지는 여기서 "페이지 만들기"로 먼저 만든다),
/// 2단계는 페이지에 구조를 이어 붙이거나 템플릿 하나를 놓는다. 고친 내용은 "저장"을 눌러야 교회 모두에게 반영된다.
/// 페이지 목록(추가·삭제·순서)은 [PageListPage]에서 다룬다.
class PageLayoutEditor extends StatefulWidget {
  const PageLayoutEditor({
    super.key,
    required this.me,
    required this.pages,
    required this.pageId,
    this.isNew = false,
  });

  final Member me;

  /// 교회의 모든 페이지. 저장할 때 이 중 [pageId]의 페이지만 고쳐서 함께 저장한다.
  final List<PageConfig> pages;
  final String pageId;

  /// 아직 만들지 않은 새 페이지. "페이지 만들기"를 눌러야 교회에 만들어지고, 그 뒤에 구조를 더할 수 있다.
  final bool isNew;

  @override
  State<PageLayoutEditor> createState() => _PageLayoutEditorState();
}

class _PageLayoutEditorState extends State<PageLayoutEditor> {
  late final List<PageConfig> _pages = List.of(widget.pages);
  late final int _index = _pages.indexWhere((p) => p.id == widget.pageId);
  late bool _isNew = widget.isNew;
  late bool _dirty = widget.isNew;

  /// 0: 페이지 개요(이름 · 위치 · 아이콘), 1: 구성(템플릿 또는 구조들).
  int _step = 0;

  /// 기도 요청 페이지의 운영 설정. 불러온 값과 고친 값(없으면 아직 안 고침).
  Future<PrayerSettings>? _prayerLoad;
  PrayerSettings? _prayerEdit;

  PageConfig get _page => _pages[_index];

  void _change(VoidCallback f) => setState(() {
    f();
    _dirty = true;
  });

  void _setPage(PageConfig p) => _change(() => _pages[_index] = p);

  void _setBlocks(List<BlockConfig> blocks) =>
      _setPage(_page.copyWith(blocks: blocks));

  void _updateBlock(int i, BlockConfig b) =>
      _setBlocks([..._page.blocks]..[i] = b);

  void _removeBlock(int i) => _setBlocks([..._page.blocks]..removeAt(i));

  void _moveBlock(int i, int delta) {
    final list = [..._page.blocks];
    final j = i + delta;
    if (j < 0 || j >= list.length) return;
    list.insert(j, list.removeAt(i));
    _setBlocks(list);
  }

  /// 이 페이지를 [to] 자리로 옮긴다. 한 칸짜리 자리의 기존 페이지는 밀려나고, 좌측 탭이 꽉 차면 옮기지 못한다.
  void _place(PageGroup to) {
    final next = PageConfig.place(_pages, _page.id, to);
    if (next == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${to.label}에는 더 둘 수 없어요.')));
      return;
    }
    _change(() => _pages.setAll(0, next));
  }

  /// 디자인 갤러리에서 구조와 디자인을 고르면 페이지 맨 아래에 이어 붙인다.
  Future<void> _addStructure() async {
    final choice = await showDesignGallery(context);
    if (choice == null) return;
    final type = choice.type;
    final source = type.sources.first;
    _setBlocks([
      ..._page.blocks,
      BlockConfig(
        id: 'b${DateTime.now().millisecondsSinceEpoch}',
        type: type,
        variant: choice.variant,
        source: source,
        title: source.label,
      ),
    ]);
  }

  /// 템플릿(기도 요청 · 말씀 묵상)을 고르면 이 페이지의 유일한 내용이 된다.
  Future<void> _addTemplate() async {
    // 기도 요청 · 말씀 묵상 운영 설정은 교회에 하나라서, 다른 페이지가 쓰는 템플릿은 고르지 못한다.
    final taken = {
      for (final p in _pages)
        if (p.id != _page.id)
          for (final b in p.blocks)
            if (b.type.wholePage) b.type,
    };
    final type = await showAppDialog<BlockType>(
      context,
      maxWidth: 420,
      child: _TemplatePicker(taken: taken),
    );
    if (type == null) return;
    _setBlocks([BlockConfig.template(type)]);
  }

  /// 새 페이지를 교회에 만든다. 만들어진 뒤에야 구조나 템플릿을 더할 수 있다.
  Future<void> _create(PageLayoutEditorViewModel vm) async {
    if (await vm.saveAll(_pages, null)) {
      setState(() {
        _isNew = false;
        _dirty = false;
        _step = 1;
      });
    }
  }

  Future<void> _save(PageLayoutEditorViewModel vm) async {
    final messenger = ScaffoldMessenger.of(context);
    // 기도 요청 운영 설정이 바뀌었으면 저장하기 전에 한 번 더 확인받는다.
    if (_prayerEdit != null &&
        !await confirmChange(
          context,
          title: '기도 요청 운영 설정을 바꿀까요?',
          body: '저장하면 모든 교인에게 바로 적용돼요.',
          confirmLabel: '저장',
        )) {
      return;
    }
    if (!mounted) return;
    if (await vm.saveAll(_pages, _prayerEdit)) {
      setState(() => _dirty = false);
      messenger.showSnackBar(const SnackBar(content: Text('페이지 구성을 저장했어요.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_index < 0) {
      return const EmptyHint('없는 페이지예요. 페이지 목록으로 돌아가 주세요.');
    }
    return ViewModelBuilder<PageLayoutEditorViewModel>(
      create: (context) => PageLayoutEditorViewModel(
        AppScope.read(context).pageLayouts,
        widget.me.churchId,
        AppScope.read(context).prayers,
        // 이 화면을 연 뒤 다른 관리자가 먼저 저장했는지 알아내는 기준.
        PageConfig.versionOf(widget.pages),
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
                      icon: const Icon(AppIcons.arrowLeft),
                      onPressed: () =>
                          context.goBack(Routes.pageList(widget.me.churchId)),
                    ),
                    Expanded(
                      child: Text(
                        // 페이지 제목 대신 지금 단계의 이름이 뒤로가기 버튼과 같은 줄에 놓인다.
                        _step == 0 ? (_isNew ? '새 페이지' : '페이지 개요') : '구성',
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
                      icon: const Icon(AppIcons.eye, size: 18),
                      label: const Text('미리보기'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 20),
                if (_step == 0) ...[
                  _pageCard(context),
                  const SizedBox(height: 24),
                  if (_isNew && vm.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        vm.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      // 이미 있는 페이지는 개요만 고치고 바로 저장할 수도 있다.
                      if (!_isNew && _dirty)
                        OutlinedButton(
                          onPressed: vm.busy || _page.title.trim().isEmpty
                              ? null
                              : () => _save(vm),
                          child: const Text('저장'),
                        ),
                      const Spacer(),
                      if (_isNew)
                        FilledButton.icon(
                          onPressed: vm.busy || _page.title.trim().isEmpty
                              ? null
                              : () => _create(vm),
                          icon: const Icon(AppIcons.plus, size: 18),
                          label: const Text('페이지 만들기'),
                        )
                      else
                        FilledButton.icon(
                          onPressed: _page.title.trim().isEmpty
                              ? null
                              : () => setState(() => _step = 1),
                          icon: const Icon(AppIcons.arrowRight, size: 18),
                          label: const Text('다음'),
                        ),
                    ],
                  ),
                ] else ...[
                  if (_page.blocks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          '구성 없음',
                          style: TextStyle(color: context.palette.muted),
                        ),
                      ),
                    ),
                  for (var i = 0; i < _page.blocks.length; i++)
                    ..._blockCard(context, vm, i),
                  _addButtons(context),
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
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => setState(() => _step = 0),
                        icon: const Icon(AppIcons.arrowLeft, size: 18),
                        label: const Text('이전'),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: vm.busy || !_dirty ? null : () => _save(vm),
                        icon: const Icon(AppIcons.check, size: 18),
                        label: Text(_dirty ? '저장' : '저장됨'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
        return editor;
      },
    );
  }

  /// 페이지에 이어 붙인 구조(또는 템플릿) 하나의 편집 카드: 순서 · 삭제 버튼과 설정.
  List<Widget> _blockCard(
    BuildContext context,
    PageLayoutEditorViewModel vm,
    int i,
  ) {
    final block = _page.blocks[i];
    final last = i == _page.blocks.length - 1;
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                block.type.wholePage
                    ? '템플릿 · ${block.type.label}'
                    : '구조 ${i + 1} · ${block.type.label}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            if (i > 0)
              IconButton(
                tooltip: '위로',
                icon: const Icon(AppIcons.caretUp),
                onPressed: () => _moveBlock(i, -1),
              ),
            if (!last)
              IconButton(
                tooltip: '아래로',
                icon: const Icon(AppIcons.caretDown),
                onPressed: () => _moveBlock(i, 1),
              ),
            IconButton(
              tooltip: block.type.wholePage ? '템플릿 삭제' : '구조 삭제',
              icon: const Icon(AppIcons.trash),
              onPressed: () => _removeBlock(i),
            ),
          ],
        ),
      ),
      _BlockEditor(
        key: ValueKey(block.id),
        churchId: widget.me.churchId,
        block: block,
        onChanged: (b) => _updateBlock(i, b),
        onManageContent: () => context.push(
          Routes.contentEdit(widget.me.churchId, kind: ContentKind.sermon),
        ),
      ),
      // 기도 요청 템플릿은 어떻게 운영할지 라디오 · 체크 · 선택 박스로 정한다.
      if (block.type == BlockType.prayer) ...[
        const SizedBox(height: 16),
        FutureBuilder<PrayerSettings>(
          future: _prayerLoad ??= vm.loadPrayerSettings(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return PrayerSettingsPanel(
              settings: _prayerEdit ?? snap.data!,
              onChanged: (v) => setState(() {
                _prayerEdit = v;
                _dirty = true;
              }),
            );
          },
        ),
      ],
      const SizedBox(height: 20),
    ];
  }

  /// 구조 추가(템플릿이 없을 때) · 템플릿 추가(비어 있고 홈이 아닐 때).
  Widget _addButtons(BuildContext context) {
    final page = _page;
    final canTemplate =
        page.blocks.isEmpty &&
        page.canBeIn(page.group) &&
        page.group != PageGroup.home;
    final canStructure =
        !page.hasTemplate && page.blocks.length < PageConfig.maxStructures;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilledButton.tonalIcon(
          onPressed: canStructure ? _addStructure : null,
          icon: const Icon(AppIcons.plus, size: 18),
          label: const Text('구조 추가'),
        ),
        OutlinedButton.icon(
          onPressed: canTemplate ? _addTemplate : null,
          icon: const Icon(AppIcons.squaresFour, size: 18),
          label: const Text('템플릿 추가'),
        ),
        if (page.group == PageGroup.home && page.blocks.isEmpty)
          Text(
            '템플릿은 홈 밖에서만',
            style: TextStyle(color: context.palette.muted, fontSize: 12),
          ),
      ],
    );
  }

  Widget _pageCard(BuildContext context) {
    final page = _page;
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
        Text('위치', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final g in PageGroup.values)
              ChoiceChip(
                label: Text(g.label),
                selected: page.group == g,
                // 템플릿 페이지는 통째로 쓰는 화면이라 홈에 둘 수 없다.
                onSelected: page.canBeIn(g) ? (_) => _place(g) : null,
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text('메뉴 아이콘', style: Theme.of(context).textTheme.titleSmall),
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

/// 템플릿 고르기: 기도 요청 · 말씀 묵상.
class _TemplatePicker extends StatelessWidget {
  const _TemplatePicker({required this.taken});

  /// 다른 페이지가 이미 쓰고 있는 템플릿.
  final Set<BlockType> taken;

  static const _icons = {
    BlockType.prayer: AppIcons.heart,
    BlockType.devotion: AppIcons.bookOpen,
  };

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('템플릿 선택', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        for (final t in _icons.keys) ...[
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.card),
            onTap: taken.contains(t) ? null : () => Navigator.pop(context, t),
            child: Ink(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: palette.surface,
                border: Border.all(color: palette.border),
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Row(
                children: [
                  Icon(_icons[t], color: palette.brand),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: taken.contains(t) ? palette.muted : null,
                      ),
                    ),
                  ),
                  if (taken.contains(t))
                    Text(
                      '사용 중',
                      style: TextStyle(color: palette.muted, fontSize: 12),
                    )
                  else
                    Icon(AppIcons.caretRight, color: palette.muted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ),
      ],
    );
  }
}

/// 이 구조가 보여줄 글의 분류 고르기: 전체, 또는 그 종류의 글에 달린 분류 중 하나.
class _CategoryPicker extends StatefulWidget {
  const _CategoryPicker({
    super.key,
    required this.churchId,
    required this.block,
    required this.onChanged,
  });

  final String churchId;
  final BlockConfig block;
  final ValueChanged<BlockConfig> onChanged;

  @override
  State<_CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<_CategoryPicker> {
  // 스트림은 한 번만 만든다 (build마다 만들면 다시 구독해 깜빡인다).
  late final Stream<List<ChurchContent>> _items = AppScope.read(context)
      .contents
      .latest(widget.churchId, widget.block.source.kind!, limit: 100);
  late final Stream<List<ContentArea>> _areas = AppScope.read(context).contents
      .areas(widget.churchId);

  @override
  Widget build(BuildContext context) {
    final current = widget.block.category;
    final kind = widget.block.source.kind!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('보여줄 글의 영역', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        StreamBuilder<List<ContentArea>>(
          stream: _areas,
          builder: (context, areas) => StreamBuilder<List<ChurchContent>>(
            stream: _items,
            builder: (context, posts) {
              final names = {
                for (final a in areas.data ?? const <ContentArea>[])
                  if (a.kind == kind) a.name,
                for (final c in posts.data ?? const <ChurchContent>[])
                  if (c.category.isNotEmpty) c.category,
                if (current.isNotEmpty) current,
              }.toList()..sort();
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('전체'),
                    selected: current.isEmpty,
                    onSelected: (_) =>
                        widget.onChanged(widget.block.copyWith(category: '')),
                  ),
                  for (final n in names)
                    ChoiceChip(
                      label: Text(n),
                      selected: current == n,
                      onSelected: (_) =>
                          widget.onChanged(widget.block.copyWith(category: n)),
                    ),
                ],
              );
            },
          ),
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
    // 기본 앱 바 대신 다른 화면처럼 뒤로가기와 제목을 맨 위 한 줄에 둔다.
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: '돌아가기',
                  icon: const Icon(AppIcons.arrowLeft),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: Text(
                    '미리보기 · ${page.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: AbsorbPointer(
                  child: ChurchPageBody(page: page, me: me),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 페이지 레이아웃의 설정: 제목 · 구조 · 자료 · 디자인 · 개수. 모두 세로로 쌓여 좁은 화면에서도 넘치지 않는다.
class _BlockEditor extends StatelessWidget {
  const _BlockEditor({
    super.key,
    required this.churchId,
    required this.block,
    required this.onChanged,
    this.onManageContent,
  });

  final String churchId;
  final BlockConfig block;
  final ValueChanged<BlockConfig> onChanged;

  /// 유튜브 "직접 게시"에서 영상을 올리는 콘텐츠 관리 화면을 연다.
  final VoidCallback? onManageContent;

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
    onChanged(block.copyWith(type: t, source: s));
  }

  @override
  Widget build(BuildContext context) {
    final type = block.type;
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 8, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 구역에서 정하는 것은 분류(고르기)와 제목(쓰기) 둘뿐이다. 같은 모양의 칸이지만 이름표와 아이콘이 다르다.
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 8, 16),
              child: LayoutBuilder(
                builder: (context, box) {
                  final category = AppDropdown<String>(
                    value: type.id,
                    label: '분류',
                    icon: AppIcons.folderOpen,
                    // 성격별로 묶고, 묶음 제목은 고를 수 없는 줄로 둔다.
                    items: [
                      // 기도 요청 · 말씀 묵상은 템플릿으로 만든 페이지라 분류를 바꾸지 않는다.
                      if (type.wholePage)
                        DropdownMenuItem(
                          value: type.id,
                          child: Text(type.label),
                        )
                      else
                        for (final (title, types) in BlockType.sections) ...[
                          DropdownMenuItem(
                            value: '#$title',
                            enabled: false,
                            child: Text(
                              title,
                              style: TextStyle(
                                color: context.palette.muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          for (final t in types)
                            DropdownMenuItem(
                              value: t.id,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(t.label),
                              ),
                            ),
                        ],
                    ],
                    onChanged: (v) {
                      if (v != null && !type.wholePage) _changeCategory(v);
                    },
                  );
                  final title = TextFormField(
                    initialValue: block.title,
                    maxLength: 30,
                    buildCounter: noCounter,
                    decoration: const InputDecoration(
                      labelText: '제목',
                      prefixIcon: Icon(AppIcons.pencilSimple),
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
            // 유튜브: 채널이나 재생목록 주소(새 영상 자동)와 한 번에 보일 영상 수.
            if (type == BlockType.video)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 8, 16),
                child: _VideoPanel(
                  block: block,
                  onChanged: onChanged,
                  onManage: onManageContent,
                ),
              ),
            // 같은 종류의 구조를 여러 개 이어 붙일 때 구조마다 보여줄 글의 분류를 고른다.
            if (block.supportsCategory && block.source.kind != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 8, 16),
                child: _CategoryPicker(
                  key: ValueKey('cat/${block.source.id}/${block.type.id}'),
                  churchId: churchId,
                  block: block,
                  onChanged: onChanged,
                ),
              ),
            // 색이 달라지는 구조는 스타일(심플·파스텔·네온)과 색 팔레트를 고른다.
            if (block.hasColor)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 8, 16),
                child: _ColorPanel(
                  style: block.style,
                  paletteId: block.paletteId,
                  onStyle: (v) => onChanged(block.copyWith(style: v)),
                  onPalette: (v) => onChanged(block.copyWith(paletteId: v)),
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
                          style: block.style,
                          paletteId: block.paletteId,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        onPressed: () => _changeDesign(context),
                        icon: const Icon(AppIcons.palette, size: 18),
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

/// 유튜브 구조의 설정: 영상을 가져오는 방식(직접 게시 · 채널 최신 영상 · 재생목록 최신 영상)과
/// 방식마다의 옵션(주소 · 최대 영상 수 1~5).
class _VideoPanel extends StatelessWidget {
  const _VideoPanel({
    required this.block,
    required this.onChanged,
    this.onManage,
  });

  final BlockConfig block;
  final ValueChanged<BlockConfig> onChanged;
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) {
    final mode = block.videoMode;
    final url = block.feedUrl.trim();
    final label = Theme.of(context).textTheme.labelLarge;
    final (min, max) = (
      BlockConfig.videoLimits.min,
      BlockConfig.videoLimits.max,
    );
    final isChannel = mode == VideoMode.channel;
    final valid = isChannel
        ? youtubeChannelTarget(url) != null
        : youtubePlaylistTarget(url) != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('영상 가져오기', style: label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in VideoMode.values)
              ChoiceChip(
                label: Text(m.label),
                selected: m == mode,
                // 방식이 바뀌면 이전 방식의 주소는 비운다.
                onSelected: (_) =>
                    onChanged(block.copyWith(videoMode: m, feedUrl: '')),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (mode != VideoMode.manual) ...[
          TextFormField(
            key: ValueKey('feed/${mode.id}'),
            initialValue: block.feedUrl,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: isChannel ? '채널 주소' : '재생목록 주소',
              hintText: isChannel
                  ? 'https://www.youtube.com/@채널'
                  : 'https://www.youtube.com/playlist?list=...',
              prefixIcon: const Icon(AppIcons.monitorPlay),
              errorText: url.isEmpty || valid
                  ? null
                  : (isChannel ? '채널 주소가 아닙니다' : '재생목록 주소가 아닙니다'),
            ),
            onChanged: (v) => onChanged(block.copyWith(feedUrl: v.trim())),
          ),
          const SizedBox(height: 16),
        ],
        Text('최대 영상 수', style: label),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: [
            for (var n = min; n <= max; n++)
              ButtonSegment(value: n, label: Text('$n')),
          ],
          selected: {block.limit.clamp(min, max)},
          onSelectionChanged: (v) => onChanged(block.copyWith(limit: v.first)),
        ),
        if (mode == VideoMode.manual && onManage != null) ...[
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onManage,
              icon: const Icon(AppIcons.bookBookmark, size: 18),
              label: const Text('설교영상 관리'),
            ),
          ),
        ],
      ],
    );
  }
}

/// 스타일(심플 · 파스텔 · 네온)과 색 팔레트를 고르는 패널.
class _ColorPanel extends StatelessWidget {
  const _ColorPanel({
    required this.style,
    required this.paletteId,
    required this.onStyle,
    required this.onPalette,
  });

  final BlockStyle style;
  final String paletteId;
  final ValueChanged<BlockStyle> onStyle;
  final ValueChanged<String> onPalette;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final label = Theme.of(context).textTheme.labelLarge;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('스타일', style: label),
          const SizedBox(height: 8),
          SegmentedButton<BlockStyle>(
            showSelectedIcon: false,
            segments: [
              for (final s in BlockStyle.values)
                ButtonSegment(value: s, label: Text(s.label)),
            ],
            selected: {style},
            onSelectionChanged: (v) => onStyle(v.first),
          ),
          const SizedBox(height: 16),
          Text('색상', style: label),
          const SizedBox(height: 8),
          // 한 줄에 다 들어가면 한 줄, 아니면 반반 나눠서 한 줄만 외톨이로 남지 않게 한다.
          LayoutBuilder(
            builder: (context, box) {
              final all = BlockPalette.all;
              final fit = ((box.maxWidth + 10) / 46).floor();
              final perRow = fit >= all.length
                  ? all.length
                  : (all.length + 1) ~/ 2;
              return SizedBox(
                width: perRow * 36.0 + (perRow - 1) * 10,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final p in all)
                      Tooltip(
                        message: p.label,
                        child: InkResponse(
                          onTap: () => onPalette(p.id),
                          radius: 24,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: p.color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: p.id == paletteId
                                    ? palette.ink
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                            child: p.id == paletteId
                                ? const Icon(
                                    AppIcons.check,
                                    color: Colors.white,
                                    size: 18,
                                  )
                                : null,
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
