import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../data/models/app_notification.dart';
import '../../auth/data/auth_repository.dart';

/// 내 알림(`users/{uid}/notifications`): 목록, 읽음 처리, 삭제.
/// 알림을 만드는 쪽(예: 교회 생성 요청 거절)은 해당 저장소가 직접 쓴다.
class NotificationRepository {
  NotificationRepository(this._db, this._auth);

  final FirebaseFirestore _db;
  final AuthRepository _auth;

  CollectionReference<Map<String, dynamic>> get _mine =>
      _db.collection('users').doc(_auth.uid).collection('notifications');

  /// 최근 알림이 위로 오는 순서.
  Stream<List<AppNotification>> notifications() => _mine
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map(AppNotification.fromDoc).toList());

  /// 아직 읽지 않은 알림 수.
  Stream<int> unreadCount() => _mine
      .where('read', isEqualTo: false)
      .snapshots()
      .map((s) => s.docs.length);

  Future<void> markRead(String id) => _mine.doc(id).update({'read': true});

  Future<void> markAllRead(Iterable<AppNotification> items) async {
    final unread = items.where((n) => !n.read).toList();
    if (unread.isEmpty) return;
    final batch = _db.batch();
    for (final n in unread) {
      batch.update(_mine.doc(n.id), {'read': true});
    }
    await batch.commit();
  }

  Future<void> delete(String id) => _mine.doc(id).delete();
}
