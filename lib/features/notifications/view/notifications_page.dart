import '../../../core/widgets/app_loader.dart';
import '../../../core/icons.dart';

import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/format.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/layout/sidebar_scaffold.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/app_notification.dart';
import '../view_model/notifications_view_model.dart';

/// 알림 탭: 내 알림 내역. 다른 화면처럼 상단 탭(뒤로가기 + 제목)이 있고,
/// 삭제는 상단의 "삭제"를 눌러 삭제 모드로 들어가 체크박스로 골라 한꺼번에 한다 (평소에는 줄에 삭제 표시가 없다).
/// 화면을 열면 읽지 않은 알림이 읽음 처리되어 버튼의 N · 숫자는 사라지지만, 알림은 지워지지 않고
/// 다음에 들어와도 그대로 볼 수 있다. 이번에 처음 본 알림에는 점과 굵은 글씨가 남아 새 것임을 알려 준다.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({
    super.key,
    this.pendingRequests = 0,
    this.onOpenRequests,
    this.onOpenMeeting,
    this.onOpenPost,
  });

  /// 승인을 기다리는 입장 요청 수. 0보다 크면 목록 맨 위에 안내가 나온다.
  final int pendingRequests;
  final VoidCallback? onOpenRequests;

  /// 모임 신청 알림을 눌렀을 때 그 모임을 연다 (교회 아이디, 모임 아이디).
  final void Function(String churchId, String meetingId)? onOpenMeeting;

  /// 내 기도제목 · 말씀묵상 글에 달린 댓글 · 좋아요 알림을 눌렀을 때 그 글을 연다 (교회 아이디, 글 종류, 글 아이디).
  final void Function(String churchId, String kind, String postId)? onOpenPost;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  /// 삭제 모드: 켜져 있을 때만 줄마다 체크박스가 보인다.
  bool _selecting = false;
  final _selected = <String>{};

  void _setSelecting(bool on) => setState(() {
    _selecting = on;
    _selected.clear();
  });

  void _toggle(String id) => setState(() {
    if (!_selected.remove(id)) _selected.add(id);
  });

  Future<void> _deleteSelected(NotificationsViewModel vm) async {
    final ok = await vm.deleteMany(_selected.toList());
    if (ok && mounted) _setSelecting(false);
  }

  /// 상단 탭: 뒤로가기 + 제목, 오른쪽에 삭제 버튼.
  /// 삭제 모드에서는 취소 · 선택 수 · 전체 선택 · 삭제가 나온다.
  Widget _bar(
    BuildContext context,
    NotificationsViewModel vm,
    List<AppNotification> items,
  ) {
    final palette = context.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final allSelected = items.isNotEmpty && _selected.length == items.length;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? palette.surface : Colors.white,
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: SidebarScaffold.menuBarHeight,
          child: Row(
            children: [
              IconButton(
                tooltip: _selecting ? '취소' : '돌아가기',
                icon: Icon(_selecting ? AppIcons.x : AppIcons.arrowLeft),
                onPressed: _selecting
                    ? () => _setSelecting(false)
                    : () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    _selecting ? '${_selected.length}개 선택' : '알림',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800, fontSize: 17),
                  ),
                ),
              ),
              if (_selecting) ...[
                TextButton(
                  onPressed: () => setState(() {
                    if (allSelected) {
                      _selected.clear();
                    } else {
                      _selected.addAll(items.map((n) => n.id));
                    }
                  }),
                  child: Text(allSelected ? '선택 해제' : '전체 선택'),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: _selected.isEmpty || vm.busy
                      ? null
                      : () => _deleteSelected(vm),
                  child: const Text('삭제'),
                ),
              ] else if (items.isNotEmpty) ...[
                // 읽지 않은 알림이 있을 때만 누를 수 있다.
                TextButton(
                  onPressed: items.any((n) => !n.read) && !vm.busy
                      ? () => vm.markAllRead(items)
                      : null,
                  child: const Text('모두 읽음'),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () => _setSelecting(true),
                  child: const Text('삭제'),
                ),
              ],
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingRequests = widget.pendingRequests;
    final onOpenRequests = widget.onOpenRequests;
    return ViewModelBuilder<NotificationsViewModel>(
      create: (context) =>
          NotificationsViewModel(AppScope.read(context).notifications),
      builder: (context, vm) => Scaffold(
        body: StreamBuilder<List<AppNotification>>(
          stream: vm.notifications,
          builder: (context, snap) {
            final items = snap.data ?? const <AppNotification>[];
            // 다른 곳에서 사라진 알림은 선택에서 뺀다.
            _selected.removeWhere((id) => !items.any((n) => n.id == id));
            return Column(
              children: [
                _bar(context, vm, items),
                Expanded(
                  child: SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      child: PageFrame(
                        inset: true,
                        verticalPadding: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (pendingRequests > 0)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Card(
                                  child: ListTile(
                                    leading: Icon(
                                      AppIcons.userPlus,
                                      color: context.palette.brand,
                                    ),
                                    title: Text('신규 입장 요청 $pendingRequests건'),
                                    subtitle: const Text('회원 관리'),
                                    trailing: const Icon(AppIcons.caretRight),
                                    // 알림 화면을 닫은 뒤 회원 관리로 이동한다.
                                    onTap: () async {
                                      final open = onOpenRequests;
                                      await Navigator.of(context).maybePop();
                                      open?.call();
                                    },
                                  ),
                                ),
                              ),
                            if (snap.hasError)
                              Text('불러오지 못했습니다\n${snap.error}')
                            else if (!snap.hasData)
                              const Padding(
                                padding: EdgeInsets.all(48),
                                child: Center(child: AppLoader()),
                              )
                            else if (items.isEmpty)
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(40),
                                  child: Center(
                                    child: Text(
                                      '알림이 없어요.',
                                      style: TextStyle(
                                        color: context.palette.muted,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            else
                              Card(
                                child: Column(
                                  children: [
                                    for (var i = 0; i < items.length; i++) ...[
                                      if (i > 0) const Divider(),
                                      _Row(
                                        item: items[i],
                                        isNew: !items[i].read,
                                        selecting: _selecting,
                                        selected: _selected.contains(
                                          items[i].id,
                                        ),
                                        onTap: () {
                                          final n = items[i];
                                          if (_selecting) return _toggle(n.id);
                                          vm.markRead(n);
                                          if (!n.hasTarget) return;
                                          final (kind, id) = n.target;
                                          Navigator.of(context).maybePop().then(
                                            (_) => kind == 'meeting'
                                                ? widget.onOpenMeeting?.call(
                                                    n.churchId,
                                                    id,
                                                  )
                                                : widget.onOpenPost?.call(
                                                    n.churchId,
                                                    kind,
                                                    id,
                                                  ),
                                          );
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.item,
    required this.isNew,
    required this.selecting,
    required this.selected,
    required this.onTap,
  });

  final AppNotification item;

  /// 이 화면에서 처음 본 알림이면 점과 굵은 글씨로 보인다.
  final bool isNew;

  /// 삭제 모드일 때만 체크박스가 보이고, 줄을 누르면 선택이 바뀐다.
  final bool selecting;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(selecting ? 4 : 16, 14, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selecting)
              SizedBox(
                width: 40,
                height: 24,
                child: Checkbox(value: selected, onChanged: (_) => onTap()),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Icon(
                  AppIcons.circleFill,
                  size: 8,
                  // 읽지 않은 알림만 점이 보인다.
                  color: isNew ? palette.brand : Colors.transparent,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: isNew ? FontWeight.w700 : FontWeight.w500,
                      // 읽은 알림은 흐리게.
                      color: isNew ? null : palette.muted,
                    ),
                  ),
                  if (item.body.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(item.body, style: TextStyle(color: palette.muted)),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    fmtDate(item.createdAt),
                    style: TextStyle(color: palette.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (!selecting && item.hasTarget)
              Icon(AppIcons.caretRight, size: 18, color: palette.muted),
          ],
        ),
      ),
    );
  }
}
