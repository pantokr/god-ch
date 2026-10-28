import '../../../core/icons.dart';

import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/format.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/app_notification.dart';
import '../view_model/notifications_view_model.dart';

/// 알림 탭: 내 알림 내역. 뒤로가기 버튼과 같은 줄에 제목이 있다.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({
    super.key,
    this.pendingRequests = 0,
    this.onOpenRequests,
  });

  /// 승인을 기다리는 입장 요청 수. 0보다 크면 목록 맨 위에 안내가 나온다.
  final int pendingRequests;
  final VoidCallback? onOpenRequests;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<NotificationsViewModel>(
      create: (context) =>
          NotificationsViewModel(AppScope.read(context).notifications),
      builder: (context, vm) => Scaffold(
        body: SafeArea(
          child: StreamBuilder<List<AppNotification>>(
            stream: vm.notifications,
            builder: (context, snap) {
              final items = snap.data ?? const <AppNotification>[];
              return SingleChildScrollView(
                child: PageFrame(
                  verticalPadding: 12,
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
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '알림',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          if (items.any((n) => !n.read))
                            TextButton(
                              onPressed: vm.busy
                                  ? null
                                  : () => vm.markAllRead(items),
                              child: const Text('모두 읽음'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (pendingRequests > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            child: ListTile(
                              leading: Icon(
                                AppIcons.userPlus,
                                color: context.palette.brand,
                              ),
                              title: Text('입장 요청 $pendingRequests건'),
                              subtitle: const Text('인원 관리에서 승인해 주세요.'),
                              trailing: const Icon(AppIcons.caretRight),
                              onTap: () {
                                Navigator.of(context).maybePop();
                                onOpenRequests?.call();
                              },
                            ),
                          ),
                        ),
                      if (snap.hasError)
                        Text('불러오지 못했습니다\n${snap.error}')
                      else if (!snap.hasData)
                        const Padding(
                          padding: EdgeInsets.all(48),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (items.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Center(
                              child: Text(
                                '새 알림이 없어요.',
                                style: TextStyle(color: context.palette.muted),
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
                                _Row(item: items[i], vm: vm),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.item, required this.vm});

  final AppNotification item;
  final NotificationsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: () => vm.markRead(item),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Icon(
                AppIcons.circleFill,
                size: 8,
                // 읽지 않은 알림만 점이 보인다.
                color: item.read ? Colors.transparent : palette.brand,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: item.read ? FontWeight.w500 : FontWeight.w700,
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
            IconButton(
              tooltip: '삭제',
              icon: const Icon(AppIcons.x, size: 18),
              onPressed: vm.busy ? null : () => vm.delete(item),
            ),
          ],
        ),
      ),
    );
  }
}
