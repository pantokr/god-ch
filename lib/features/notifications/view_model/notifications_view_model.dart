import '../../../core/mvvm/view_model.dart';
import '../../../data/models/app_notification.dart';
import '../data/notification_repository.dart';

/// 알림 탭: 알림 목록과 읽음 처리·삭제. 스트림은 한 번만 만든다.
class NotificationsViewModel extends ViewModel {
  NotificationsViewModel(this._repository)
    : notifications = _repository.notifications();

  final NotificationRepository _repository;
  final Stream<List<AppNotification>> notifications;

  Future<bool> markRead(AppNotification n) =>
      n.read ? Future.value(true) : run(() => _repository.markRead(n.id));

  Future<bool> markAllRead(List<AppNotification> items) =>
      run(() => _repository.markAllRead(items));

  Future<bool> delete(AppNotification n) => run(() => _repository.delete(n.id));
}
