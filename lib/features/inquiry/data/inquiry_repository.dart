import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/app_exception.dart';
import '../../../data/firestore_codec.dart';
import '../../../data/models/app_notification.dart';
import '../../../data/models/inquiry.dart';
import '../../activity/data/activity_log_repository.dart';
import '../../auth/data/auth_repository.dart';

/// 문의 (`inquiries`): 로그인한 누구나 앱 운영자에게 보내고, 앱 운영자가 답변한다.
/// 문서 ID는 시간 역순이라 복합 색인 없이 이름순이 곧 최신순이다 ([ActivityLogRepository.newId]).
class InquiryRepository {
  InquiryRepository(this._db, this._auth);

  final FirebaseFirestore _db;
  final AuthRepository _auth;

  CollectionReference<Json> get _col => _db.collection('inquiries');

  // ---- 보내는 사람 ----

  /// 내가 보낸 문의 (최신 순).
  Stream<List<Inquiry>> mine({int limit = 100}) => _col
      .where('uid', isEqualTo: _auth.uid)
      .limit(limit)
      .snapshots()
      .map(_parse);

  Future<void> send({required String title, required String message}) async {
    final t = title.trim();
    final m = message.trim();
    if (t.isEmpty) throw const AppException('제목을 입력해 주세요.');
    if (m.isEmpty) throw const AppException('내용을 입력해 주세요.');
    if (t.length > Inquiry.maxTitle) {
      throw const AppException('제목은 ${Inquiry.maxTitle}자까지 쓸 수 있어요.');
    }
    if (m.length > Inquiry.maxMessage) {
      throw const AppException('내용은 ${Inquiry.maxMessage}자까지 쓸 수 있어요.');
    }
    await _col.doc(ActivityLogRepository.newId()).set({
      'uid': _auth.uid,
      'userName': _auth.displayName,
      'title': t,
      'message': m,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 내 문의를 지운다 (답변이 있어도 지울 수 있다).
  Future<void> remove(String id) => _col.doc(id).delete();

  // ---- 앱 운영자 ----

  /// 모든 문의 (앱 운영자 전용, 최신 순).
  Stream<List<Inquiry>> all({int limit = 200}) =>
      _col.limit(limit).snapshots().map(_parse);

  /// 답변을 달고 보낸 사람에게 알린다.
  Future<void> answer(Inquiry inquiry, String text) {
    final a = text.trim();
    if (a.isEmpty) throw const AppException('답변을 입력해 주세요.');
    if (a.length > Inquiry.maxAnswer) {
      throw const AppException('답변은 ${Inquiry.maxAnswer}자까지 쓸 수 있어요.');
    }
    final batch = _db.batch();
    batch.update(_col.doc(inquiry.id), {
      'status': 'answered',
      'answer': a,
      'answeredAt': FieldValue.serverTimestamp(),
      'answeredBy': _auth.uid,
    });
    batch.set(
      _db
          .collection('users')
          .doc(inquiry.uid)
          .collection('notifications')
          .doc(),
      {
        'type': NotificationType.general.name,
        'title': '문의에 답변이 달렸어요',
        'body': inquiry.title,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
    return batch.commit();
  }

  List<Inquiry> _parse(QuerySnapshot<Json> s) => [
    for (final d in s.docs) Inquiry.fromDoc(d),
  ];
}
