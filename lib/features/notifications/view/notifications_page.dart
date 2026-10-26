import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/format.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/app_notification.dart';
import '../view_model/notifications_view_model.dart';

/// 알림 탭: 내 알림 내역. 상단 바 없이 뒤로가기 버튼만 내용 위에 있다.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

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
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          tooltip: '돌아가기',
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                      PageTitle(
                        title: '알림',
                        subtitle: '내게 온 알림 내역이에요.',
                        action: items.any((n) => !n.read)
                            ? TextButton(
                                onPressed: vm.busy
                                    ? null
                                    : () => vm.markAllRead(items),
                                child: const Text('모두 읽음'),
                              )
                            : null,
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
                Icons.circle,
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
              icon: const Icon(Icons.close, size: 18),
              onPressed: vm.busy ? null : () => vm.delete(item),
            ),
          ],
        ),
      ),
    );
  }
}
