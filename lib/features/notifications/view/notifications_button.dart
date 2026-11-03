import '../../../core/icons.dart';

import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/layout/sidebar_scaffold.dart' show PanelCloser;
import 'notifications_page.dart';

/// 오른쪽 계정 띠의 프로필 아래에 놓는 알림 버튼. 읽지 않은 알림(또는 입장 요청)이 있으면 N 배지가 보인다.
class NotificationsButton extends StatefulWidget {
  const NotificationsButton({
    super.key,
    this.pendingRequests = 0,
    this.onOpenRequests,
  });

  /// 승인을 기다리는 입장 요청 수 (교역자·교회 운영자에게만 넘긴다). 알림 목록 맨 위에 안내로 보인다.
  final int pendingRequests;
  final VoidCallback? onOpenRequests;

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
        // 읽지 않은 알림이나 처리할 입장 요청이 있으면 N으로 표시한다.
        final hasNew = count > 0 || widget.pendingRequests > 0;
        return IconButton(
          tooltip: '알림',
          onPressed: () {
            // 좁은 화면에서는 이 버튼이 서랍(계정 띠) 안에 있다: 입장 요청으로 이동할 때 서랍을 함께 닫는다.
            final closeDrawer = PanelCloser.of(context);
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => NotificationsPage(
                  pendingRequests: widget.pendingRequests,
                  onOpenRequests: () {
                    closeDrawer?.call();
                    widget.onOpenRequests?.call();
                  },
                ),
              ),
            );
          },
          icon: Badge(
            isLabelVisible: hasNew,
            label: const Text('N'),
            child: const Icon(AppIcons.bell),
          ),
        );
      },
    );
  }
}
