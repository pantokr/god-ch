import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import 'notifications_page.dart';

/// 오른쪽 계정 띠의 프로필 아래에 놓는 알림 버튼. 읽지 않은 알림 수가 배지로 보인다.
class NotificationsButton extends StatefulWidget {
  const NotificationsButton({super.key});

  @override
  State<NotificationsButton> createState() => _NotificationsButtonState();
}

class _NotificationsButtonState extends State<NotificationsButton> {
  // 스트림은 한 번만 만든다 (build마다 새로 만들면 재구독으로 깜빡인다).
  Stream<int>? _unread;

  @override
  Widget build(BuildContext context) {
    _unread ??= AppScope.read(context).notifications.unreadCount();
    return StreamBuilder<int>(
      stream: _unread,
      builder: (context, snap) {
        final count = snap.data ?? 0;
        return IconButton(
          tooltip: '알림',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const NotificationsPage()),
          ),
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text(count > 9 ? '9+' : '$count'),
            child: const Icon(Icons.notifications_none),
          ),
        );
      },
    );
  }
}
