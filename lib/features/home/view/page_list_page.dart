import '../../../core/icons.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/layout/app_dialog.dart';
import '../../../core/layout/confirm_dialog.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/member.dart';
import '../../../data/models/page_layout.dart';
import '../view_model/church_pages_view_model.dart';
import 'page_icons.dart';
import 'placement_editor.dart';

/// 페이지 편집: 교회의 페이지를 나열하고 추가 · 삭제 · 배치 설정(위치와 순서)을 한다. 구조와 템플릿은 페이지를 연 뒤 그 안에서 더한다.
/// 위치와 순서는 줄 오른쪽 "배치 설정"에서 실제 앱과 비슷한 화면 안에서 끌어서 정한다.
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
        null,
        // 이 화면을 연 뒤 다른 관리자가 먼저 저장했는지 알아내는 기준.
        PageConfig.versionOf(pages),
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
              // 페이지를 나열한다: 각 줄에 속한 위치가 보이고, 오른쪽 "배치 설정"에서 위치와 순서를 정한다.
              _PageTiles(
                pages: pages,
                busy: vm.busy,
                canDelete: pages.length > 1,
                onEdit: (p) => context.push(Routes.pageEdit(me.churchId, p.id)),
                onArrange: (p) => _arrange(context, vm, p),
                onDelete: (p) => _delete(context, vm, p),
              ),
              const SizedBox(height: 20),
              // 내 활동은 직접 고치지 않는다. 기도 요청 · 말씀 묵상 템플릿에 따라 자동으로 정해진다.
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
      onPressed: vm.busy || pages.length >= 12 ? null : () => _add(context),
      icon: const Icon(AppIcons.plus, size: 18),
      label: const Text('페이지 추가'),
    );
    final start = OutlinedButton.icon(
      onPressed: vm.busy ? null : () => _chooseStart(context, vm),
      icon: const Icon(AppIcons.squaresFour, size: 18),
      label: const Text('시작 구성'),
    );
    final history = OutlinedButton.icon(
      onPressed: vm.busy ? null : () => _restore(context, vm),
      icon: const Icon(AppIcons.arrowCounterClockwise, size: 18),
      label: const Text('이전 구성'),
    );
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        SizedBox(width: narrow ? double.infinity : null, child: button),
        SizedBox(width: narrow ? double.infinity : null, child: start),
        SizedBox(width: narrow ? double.infinity : null, child: history),
      ],
    );
  }

  /// 시작 구성(기본 · 소규모 교회 · 청년부 중심) 중 하나로 바꾼다. 바꾸기 전 구성은 이전 구성에 남는다.
  Future<void> _chooseStart(
    BuildContext context,
    PageLayoutEditorViewModel vm,
  ) async {
    final preset = await showAppDialog<PagePreset>(
      context,
      maxWidth: 460,
      child: const _PresetDialog(),
    );
    if (preset == null || !context.mounted) return;
    final ok = await confirmChange(
      context,
      title: '${preset.label}으로 바꾸기',
      body: '지금 페이지들이 이 구성으로 바뀌어요. 바꾸기 전 구성은 이전 구성에 남아요.',
      confirmLabel: '바꾸기',
    );
    if (!ok) return;
    final keep = {for (final d in preset.pages) d.id};
    await vm.save(preset.pages, [
      for (final p in pages)
        if (!keep.contains(p.id)) p.id,
    ]);
  }

  /// 저장 직전에 남겨 둔 이전 구성 중 하나로 되돌린다.
  Future<void> _restore(
    BuildContext context,
    PageLayoutEditorViewModel vm,
  ) async {
    final revision = await showAppDialog<PageRevision>(
      context,
      maxWidth: 520,
      child: _RevisionsDialog(churchId: me.churchId),
    );
    if (revision == null || !context.mounted) return;
    final ok = await confirmChange(
      context,
      title: '이전 구성으로 되돌리기',
      body: '지금 구성이 이 시점의 구성으로 바뀌어요. 지금 구성도 이전 구성에 남아요.',
      confirmLabel: '되돌리기',
    );
    if (!ok) return;
    await vm.restore(revision, pages);
  }

  /// 새 페이지를 만든다: 이름 · 위치 · 아이콘만 정하는 편집 화면이 열리고,
  /// "페이지 만들기"를 눌러야 교회에 만들어진다. 구조나 템플릿은 만들어진 뒤에 페이지 안에서 더한다.
  void _add(BuildContext context) {
    final id = 'p${DateTime.now().millisecondsSinceEpoch}';
    context.push(
      Routes.pageEdit(me.churchId, id),
      extra: PageConfig(id: id, title: '', icon: 'star'),
    );
  }

  /// 배치 설정: 실제 앱과 비슷한 화면에서 페이지의 위치와 순서를 끌어서 정한다.
  Future<void> _arrange(
    BuildContext context,
    PageLayoutEditorViewModel vm,
    PageConfig focus,
  ) => showAppDialog<void>(
    context,
    maxWidth: 420,
    child: PlacementEditor(
      pages: pages,
      focusId: focus.id,
      onSave: (next) async =>
          await vm.save(next, const []) ? null : (vm.error ?? '저장하지 못했어요.'),
    ),
  );

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

/// 페이지 목록: 페이지마다 속한 위치가 보이고, 오른쪽에 배치 설정 · 수정 · 더 보기(삭제) 버튼이 있다.
/// 줄을 누르면 그 페이지의 구성을 고치는 화면이 열린다.
class _PageTiles extends StatelessWidget {
  const _PageTiles({
    required this.pages,
    required this.busy,
    required this.canDelete,
    required this.onEdit,
    required this.onArrange,
    required this.onDelete,
  });

  final List<PageConfig> pages;
  final bool busy;

  /// 페이지가 둘 이상일 때만 지울 수 있다.
  final bool canDelete;
  final void Function(PageConfig) onEdit;
  final void Function(PageConfig) onArrange;
  final void Function(PageConfig) onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final narrow = MediaQuery.sizeOf(context).width < 600;
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
        child: Column(
          children: [
            for (var i = 0; i < pages.length; i++) ...[
              if (i > 0) Divider(height: 1, color: palette.border),
              ListTile(
                onTap: () => onEdit(pages[i]),
                leading: Icon(pageIconOf(pages[i].icon).outlined),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(
                        pages[i].title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _LocationBadge(group: pages[i].group),
                  ],
                ),
                subtitle: Text(_summary(pages[i])),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (narrow)
                      IconButton(
                        tooltip: '배치 설정',
                        icon: const Icon(AppIcons.squaresFour, size: 20),
                        onPressed: busy ? null : () => onArrange(pages[i]),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: busy ? null : () => onArrange(pages[i]),
                        icon: const Icon(AppIcons.squaresFour, size: 18),
                        label: const Text('배치 설정'),
                      ),
                    IconButton(
                      tooltip: '수정',
                      icon: const Icon(AppIcons.pencilSimple, size: 20),
                      onPressed: () => onEdit(pages[i]),
                    ),
                    PopupMenuButton<VoidCallback>(
                      tooltip: '더 보기',
                      enabled: !busy,
                      onSelected: (a) => a(),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: () => onDelete(pages[i]),
                          enabled: canDelete,
                          child: Text(canDelete ? '삭제' : '삭제 (최소 1개는 남겨야 해요)'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 페이지가 속한 위치(홈 · 왼쪽 버튼 · 오른쪽 버튼 · 좌측 탭) 표시.
class _LocationBadge extends StatelessWidget {
  const _LocationBadge({required this.group});

  final PageGroup group;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: palette.brand.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        group.label,
        style: TextStyle(
          color: palette.brand,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// 페이지 한 줄의 요약: 템플릿 하나, 또는 이어 붙인 구조들.
String _summary(PageConfig p) {
  if (p.blocks.isEmpty) return '구성 없음';
  if (p.hasTemplate) return '템플릿 · ${p.template!.type.label}';
  return '구조 ${p.blocks.length}개 · ${p.blocks.map((b) => b.type.label).join(', ')}';
}

/// 내 활동 미리보기: 기도 요청 · 말씀 묵상 템플릿에 따라 자동으로 정해지는 항목들 (고칠 수 없다).
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
                    avatar: Icon(
                      AppIcons.check,
                      size: 16,
                      color: palette.brand,
                    ),
                    label: Text(a.label),
                  ),
              ],
            ),
    );
  }
}

/// 시작 구성 고르기.
class _PresetDialog extends StatelessWidget {
  const _PresetDialog();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('시작 구성', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        for (final p in PageConfig.presets) ...[
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.card),
            onTap: () => Navigator.pop(context, p),
            child: Ink(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.surface,
                border: Border.all(color: palette.border),
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.label,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.summary,
                          style: TextStyle(color: palette.muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
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

String _stamp(DateTime? t) {
  if (t == null) return '방금';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${t.year}.${two(t.month)}.${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
}

/// 이전 구성 목록: 저장할 때마다 남은 직전 구성 중 최근 10개.
class _RevisionsDialog extends StatefulWidget {
  const _RevisionsDialog({required this.churchId});

  final String churchId;

  @override
  State<_RevisionsDialog> createState() => _RevisionsDialogState();
}

class _RevisionsDialogState extends State<_RevisionsDialog> {
  late final Stream<List<PageRevision>> _revisions = AppScope.read(context)
      .pageLayouts
      .revisions(widget.churchId);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('이전 구성', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Flexible(
          child: StreamBuilder<List<PageRevision>>(
            stream: _revisions,
            builder: (context, snap) {
              if (snap.hasError) return const Text('불러오지 못했어요.');
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final items = snap.data!;
              if (items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      '기록 없음',
                      style: TextStyle(color: palette.muted),
                    ),
                  ),
                );
              }
              return ListView(
                shrinkWrap: true,
                children: [
                  for (final r in items)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_stamp(r.savedAt)),
                      subtitle: Text(
                        r.pages.map((p) => p.title).join(', '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: TextButton(
                        onPressed: () => Navigator.pop(context, r),
                        child: const Text('복원'),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ),
      ],
    );
  }
}
