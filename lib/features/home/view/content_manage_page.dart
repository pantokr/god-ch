import '../../../core/icons.dart';

import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/format.dart';
import '../../../core/layout/app_dialog.dart';
import '../../../core/layout/confirm_dialog.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/church_content.dart';
import '../../../data/models/member.dart';
import '../../../data/models/page_layout.dart';
import '../view_model/content_list_view_model.dart';
import '../view_model/content_overview_view_model.dart';
import 'content_edit_page.dart';

/// 콘텐츠 관리: 교회 관리자나 교역자가 올린 모든 글을 한곳에 나열한다.
/// 글마다 종류 · 영역과 "표시되는 곳"(그 글이 보이는 페이지)을 알려 주고,
/// 글을 개별로 또는 여럿 골라 다른 영역으로 옮길 수 있다. 영역은 비어 있어야만 지울 수 있다.
/// 페이지의 구성(위치, 구조)은 "페이지 편집"에서 따로 고친다.
class ContentManagePage extends StatefulWidget {
  const ContentManagePage({super.key, required this.me, required this.pages});

  final Member me;

  /// 교회의 페이지들 (글이 보이는 곳을 알려 주는 데 쓴다).
  final List<PageConfig> pages;

  @override
  State<ContentManagePage> createState() => _ContentManagePageState();
}

class _ContentManagePageState extends State<ContentManagePage> {
  static const _icons = {
    ContentKind.notice: AppIcons.megaphone,
    ContentKind.event: AppIcons.calendarBlank,
    ContentKind.photo: AppIcons.images,
    ContentKind.sermon: AppIcons.monitorPlay,
    ContentKind.devotion: AppIcons.bookOpen,
  };

  /// 보고 있는 종류 · 영역 (null이면 전체, 영역 ''는 영역 없음).
  ContentKind? _kind;
  String? _area;

  /// 옮기려고 고른 글 (`종류/글 번호`).
  final _selected = <String>{};

  String _key(ChurchContent c) => '${c.kind.collection}/${c.id}';

  /// 글이 보이는 곳 표시: "공지사항(홈), 소식(좌측 탭)" 또는 "표시되는 곳 없음".
  String _shownIn(ChurchContent c) {
    final shown = PageConfig.showing(widget.pages, c);
    if (shown.isEmpty) return '표시되는 곳 없음';
    final names = [for (final p in shown) '${p.title}(${p.group.label})'];
    return names.length <= 2
        ? names.join(', ')
        : '${names.take(2).join(', ')} 외 ${names.length - 2}곳';
  }

  ContentListViewModel _listVm(ContentKind kind) => ContentListViewModel(
    AppScope.read(context).contents,
    widget.me.churchId,
    kind,
  );

  Future<void> _add(ContentOverviewViewModel vm) async {
    final kind = await showAppDialog<ContentKind>(
      context,
      maxWidth: 420,
      child: const _KindPicker(),
    );
    if (kind == null || !mounted) return;
    final lvm = _listVm(kind);
    await editContent(context, lvm, areas: vm.areaNames(kind));
    lvm.dispose();
  }

  Future<void> _edit(ContentOverviewViewModel vm, ChurchContent c) async {
    final lvm = _listVm(c.kind);
    await editContent(context, lvm, content: c, areas: vm.areaNames(c.kind));
    lvm.dispose();
  }

  Future<void> _delete(ContentOverviewViewModel vm, ChurchContent c) async {
    final ok = await confirmChange(
      context,
      title: '${c.kind.label} 삭제',
      body: '"${c.title}"을(를) 삭제할까요? 목록에서 사라지고 기록으로만 남아요.',
      confirmLabel: '삭제',
    );
    if (!ok) return;
    _selected.remove(_key(c));
    await vm.delete(c);
  }

  /// [items](모두 같은 종류)를 옮길 영역을 고르고 옮긴다.
  Future<void> _moveTo(
    ContentOverviewViewModel vm,
    ContentKind kind,
    List<ChurchContent> items, {
    String? except,
  }) async {
    final target = await showAppDialog<String>(
      context,
      maxWidth: 420,
      child: _AreaPicker(
        kind: kind,
        names: [
          for (final n in vm.areaNames(kind))
            if (n != except) n,
        ],
        allowNone: except != '',
        count: items.length,
      ),
    );
    if (target == null) return;
    if (await vm.move(items, target)) {
      setState(() => _selected.removeAll(items.map(_key)));
    }
  }

  Future<void> _manageAreas(ContentOverviewViewModel vm) => showAppDialog<void>(
    context,
    maxWidth: 520,
    child: _AreaManager(
      vm: vm,
      onMoveAll: (kind, name) =>
          _moveTo(vm, kind, vm.postsIn(kind, name), except: name),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final error = Theme.of(context).colorScheme.error;
    return ViewModelBuilder<ContentOverviewViewModel>(
      create: (context) => ContentOverviewViewModel(
        AppScope.read(context).contents,
        widget.me.churchId,
      ),
      builder: (context, vm) {
        final all = vm.all;
        final shown = [
          for (final c in all)
            if ((_kind == null || c.kind == _kind) &&
                (_area == null || c.category == _area))
              c,
        ];
        final picked = [
          for (final c in all)
            if (_selected.contains(_key(c))) c,
        ];
        // 고른 글은 한 종류만 함께 옮긴다 (영역은 종류 안에서만 있다).
        final lockKind = picked.isEmpty ? null : picked.first.kind;
        return SingleChildScrollView(
          child: PageFrame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageTitle(
                  title: '콘텐츠 관리',
                  action: Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: vm.busy ? null : () => _manageAreas(vm),
                        icon: const Icon(AppIcons.folderOpen, size: 18),
                        label: const Text('영역 관리'),
                      ),
                      FilledButton.icon(
                        onPressed: vm.busy ? null : () => _add(vm),
                        icon: const Icon(AppIcons.plus, size: 18),
                        label: const Text('글 추가'),
                      ),
                    ],
                  ),
                ),
                // 종류 거르기
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text('전체 ${all.length}'),
                      selected: _kind == null,
                      onSelected: (_) => setState(() {
                        _kind = null;
                        _area = null;
                      }),
                    ),
                    for (final k in ContentKind.values)
                      ChoiceChip(
                        avatar: Icon(_icons[k], size: 16),
                        label: Text('${k.label} ${vm.postsOf(k).length}'),
                        selected: _kind == k,
                        onSelected: (_) => setState(() {
                          _kind = k;
                          _area = null;
                        }),
                      ),
                  ],
                ),
                // 영역 거르기 (영역이 있는 종류를 골랐을 때)
                if (_kind != null && _kind!.hasAreas) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('모든 영역'),
                        selected: _area == null,
                        onSelected: (_) => setState(() => _area = null),
                      ),
                      ChoiceChip(
                        label: Text('영역 없음 ${vm.postsIn(_kind!, '').length}'),
                        selected: _area == '',
                        onSelected: (_) => setState(() => _area = ''),
                      ),
                      for (final n in vm.areaNames(_kind!))
                        ChoiceChip(
                          label: Text('$n ${vm.postsIn(_kind!, n).length}'),
                          selected: _area == n,
                          onSelected: (_) => setState(() => _area = n),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                if (picked.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: palette.brand.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.control),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${picked.length}개 선택',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        FilledButton.tonal(
                          onPressed: vm.busy
                              ? null
                              : () => _moveTo(vm, lockKind!, picked),
                          child: const Text('영역 옮기기'),
                        ),
                        TextButton(
                          onPressed: () => setState(_selected.clear),
                          child: const Text('선택 해제'),
                        ),
                      ],
                    ),
                  ),
                if (vm.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(vm.error!, style: TextStyle(color: error)),
                  ),
                if (vm.loading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (shown.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        '등록된 글 없음',
                        style: TextStyle(color: palette.muted),
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: palette.surface,
                      border: Border.all(color: palette.border),
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Material(
                      type: MaterialType.transparency,
                      child: Column(
                        children: [
                          for (var i = 0; i < shown.length; i++) ...[
                            if (i > 0)
                              Divider(height: 1, color: palette.border),
                            _row(vm, shown[i], lockKind),
                          ],
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _row(
    ContentOverviewViewModel vm,
    ChurchContent c,
    ContentKind? lockKind,
  ) {
    final palette = context.palette;
    final selectable =
        c.kind.hasAreas && (lockKind == null || lockKind == c.kind);
    final area = !c.kind.hasAreas
        ? null
        : c.category.isEmpty
        ? '영역 없음'
        : c.category;
    return ListTile(
      onTap: () => _edit(vm, c),
      leading: c.kind.hasAreas
          ? Checkbox(
              value: _selected.contains(_key(c)),
              onChanged: selectable
                  ? (v) => setState(
                      () => v == true
                          ? _selected.add(_key(c))
                          : _selected.remove(_key(c)),
                    )
                  : null,
            )
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(_icons[c.kind], size: 20, color: palette.muted),
            ),
      title: Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [c.kind.label, ?area, fmtDate(c.date)].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            _shownIn(c),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _shownIn(c) == '표시되는 곳 없음' ? palette.muted : palette.brand,
              fontSize: 12,
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (c.kind.hasAreas)
            IconButton(
              tooltip: '영역 옮기기',
              icon: const Icon(AppIcons.folderOpen, size: 20),
              onPressed: vm.busy ? null : () => _moveTo(vm, c.kind, [c]),
            ),
          IconButton(
            tooltip: '수정',
            icon: const Icon(AppIcons.pencilSimple, size: 20),
            onPressed: () => _edit(vm, c),
          ),
          IconButton(
            tooltip: '삭제',
            icon: const Icon(AppIcons.trash, size: 20),
            onPressed: vm.busy ? null : () => _delete(vm, c),
          ),
        ],
      ),
    );
  }
}

/// 새 글의 종류 고르기.
class _KindPicker extends StatelessWidget {
  const _KindPicker();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('종류 선택', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        for (final k in ContentKind.values)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(k.label),
            trailing: Icon(AppIcons.caretRight, color: context.palette.muted),
            onTap: () => Navigator.pop(context, k),
          ),
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

/// 옮길 영역 고르기. 빈 문자열은 영역 없음.
class _AreaPicker extends StatelessWidget {
  const _AreaPicker({
    required this.kind,
    required this.names,
    required this.allowNone,
    required this.count,
  });

  final ContentKind kind;
  final List<String> names;
  final bool allowNone;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${kind.label} $count개 옮기기',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              if (allowNone)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('영역 없음'),
                  onTap: () => Navigator.pop(context, ''),
                ),
              for (final n in names)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(n),
                  onTap: () => Navigator.pop(context, n),
                ),
              if (!allowNone && names.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '옮길 영역 없음',
                    style: TextStyle(color: context.palette.muted),
                  ),
                ),
            ],
          ),
        ),
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

/// 영역 관리: 종류마다 영역을 만들고, 영역 안의 글을 모두 옮기고, 비어 있는 영역을 지운다.
class _AreaManager extends StatefulWidget {
  const _AreaManager({required this.vm, required this.onMoveAll});

  final ContentOverviewViewModel vm;

  /// 영역 안의 글을 모두 다른 영역으로 옮긴다 (옮길 곳 고르기까지).
  final Future<void> Function(ContentKind kind, String name) onMoveAll;

  @override
  State<_AreaManager> createState() => _AreaManagerState();
}

class _AreaManagerState extends State<_AreaManager> {
  final _inputs = {
    for (final k in ContentKind.values.where((k) => k.hasAreas))
      k: TextEditingController(),
  };

  @override
  void dispose() {
    for (final c in _inputs.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _add(ContentKind kind) async {
    final c = _inputs[kind]!;
    if (await widget.vm.addArea(kind, c.text)) c.clear();
  }

  Future<void> _delete(ContentKind kind, String name) async {
    final ok = await confirmChange(
      context,
      title: '영역 삭제',
      body: '"$name" 영역을 삭제할까요?',
      confirmLabel: '삭제',
    );
    if (ok) await widget.vm.deleteArea(kind, name);
  }

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return ListenableBuilder(
      listenable: widget.vm,
      builder: (context, _) {
        final vm = widget.vm;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('영역 관리', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final kind in _inputs.keys) ...[
                      Text(
                        kind.label,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      _row(
                        context,
                        name: '영역 없음',
                        count: vm.postsIn(kind, '').length,
                        onMoveAll: () => widget.onMoveAll(kind, ''),
                      ),
                      for (final n in vm.areaNames(kind))
                        _row(
                          context,
                          name: n,
                          count: vm.postsIn(kind, n).length,
                          onMoveAll: () => widget.onMoveAll(kind, n),
                          onDelete: () => _delete(kind, n),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _inputs[kind],
                              maxLength: ChurchContent.maxCategoryLength,
                              buildCounter: (
                                context, {
                                required currentLength,
                                required isFocused,
                                required maxLength,
                              }) => null,
                              decoration: const InputDecoration(
                                labelText: '새 영역 이름',
                              ),
                              onSubmitted: (_) => _add(kind),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: vm.busy ? null : () => _add(kind),
                            child: const Text('만들기'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
            if (vm.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(vm.error!, style: TextStyle(color: error)),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('닫기'),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 영역 한 줄: 이름과 글 수, 글이 있으면 "모두 옮기기", 글이 없으면 삭제 (영역 없음은 지울 수 없다).
  Widget _row(
    BuildContext context, {
    required String name,
    required int count,
    required VoidCallback onMoveAll,
    VoidCallback? onDelete,
  }) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(name)),
          Text('$count개', style: TextStyle(color: palette.muted)),
          const SizedBox(width: 8),
          if (count > 0)
            TextButton(onPressed: onMoveAll, child: const Text('모두 옮기기'))
          else if (onDelete != null)
            IconButton(
              tooltip: '영역 삭제',
              icon: const Icon(AppIcons.trash, size: 20),
              onPressed: widget.vm.busy ? null : onDelete,
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}
