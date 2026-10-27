import 'package:flutter/material.dart';

import '../../../core/back_navigation.dart';
import '../../../core/layout/confirm_dialog.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/block_style.dart';
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

/// 한 페이지의 구성 편집: 이름·아이콘을 고치고, 이 페이지의 레이아웃(구조 + 디자인) 하나를 고른다. 고친 내용은 "저장"을 눌러야 교회 모두에게 반영된다.
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

  /// 아직 저장하지 않은 새 페이지. 저장하기 전에는 교회에 만들어지지 않는다.
  final bool isNew;

  @override
  State<PageLayoutEditor> createState() => _PageLayoutEditorState();
}

class _PageLayoutEditorState extends State<PageLayoutEditor> {
  late final List<PageConfig> _pages = List.of(widget.pages);
  late final int _index = _pages.indexWhere((p) => p.id == widget.pageId);
  // 새 페이지는 처음부터 저장할 수 있다 (저장해야 만들어진다).
  late bool _dirty = widget.isNew;

  /// 0: 메뉴 개요(이름 · 그룹 · 아이콘), 1: 레이아웃. 개요를 마치고 "다음"을 누르면 레이아웃으로 넘어간다.
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

  void _setLayout(BlockConfig b) => _setPage(_page.copyWith(layout: b));

  /// 디자인 갤러리에서 실제 모습을 보고 이 페이지의 레이아웃을 고른다.
  Future<void> _pickLayout() async {
    final choice = await showDesignGallery(context);
    if (choice == null) return;
    final type = choice.type;
    final source = type.sources.first;
    _setLayout(
      BlockConfig(
        id: _page.layout?.id ?? 'b${DateTime.now().millisecondsSinceEpoch}',
        type: type,
        variant: choice.variant,
        source: source,
        title: source.label,
      ),
    );
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
                if (_step == 0) ...[
                  const _SectionHeader(
                    icon: Icons.menu_open_outlined,
                    title: '메뉴 개요',
                  ),
                  _pageCard(context),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      // 이미 있는 페이지는 개요만 고치고 바로 저장할 수도 있다.
                      if (!widget.isNew && _dirty)
                        OutlinedButton(
                          onPressed: vm.busy || _page.title.trim().isEmpty
                              ? null
                              : () => _save(vm),
                          child: const Text('저장'),
                        ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: _page.title.trim().isEmpty
                            ? null
                            : () => setState(() => _step = 1),
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: const Text('다음'),
                      ),
                    ],
                  ),
                ] else ...[
                  const _SectionHeader(
                    icon: Icons.view_agenda_outlined,
                    title: '레이아웃',
                  ),
                  if (_page.layout == null)
                    Center(
                      child: FilledButton.icon(
                        onPressed: _pickLayout,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('레이아웃 고르기'),
                      ),
                    )
                  else
                    _BlockEditor(
                      key: ValueKey(_page.layout!.id),
                      block: _page.layout!,
                      onChanged: _setLayout,
                    ),
                  // 기도 요청 페이지는 어떻게 운영할지 라디오 · 체크 · 선택 박스로 정한다.
                  if (_page.layout?.type == BlockType.prayer) ...[
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
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text('이전'),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: vm.busy || !_dirty ? null : () => _save(vm),
                        icon: const Icon(Icons.check, size: 18),
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
        SegmentedButton<PageGroup>(
          showSelectedIcon: false,
          segments: [
            for (final g in PageGroup.values)
              ButtonSegment(value: g, label: Text(g.label)),
          ],
          selected: {page.group},
          onSelectionChanged: (v) => _setPage(page.copyWith(group: v.first)),
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
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ],
      ),
    );
  }
}

/// 페이지 레이아웃의 설정: 제목 · 구조 · 자료 · 디자인 · 개수. 모두 세로로 쌓여 좁은 화면에서도 넘치지 않는다.
class _BlockEditor extends StatelessWidget {
  const _BlockEditor({super.key, required this.block, required this.onChanged});

  final BlockConfig block;
  final ValueChanged<BlockConfig> onChanged;

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
                    icon: Icons.folder_open_outlined,
                    // 성격별로 묶고, 묶음 제목은 고를 수 없는 줄로 둔다.
                    items: [
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
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final p in BlockPalette.all)
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
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            )
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
