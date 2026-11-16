import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_codec.dart';

/// 앱 운영자에게 보내는 문의 (`inquiries/{id}`). 보낸 사람과 앱 운영자만 읽는다.
/// 운영자가 답변을 달면 [answered]가 된다.
class Inquiry {
  const Inquiry({
    required this.id,
    required this.uid,
    required this.userName,
    required this.title,
    required this.message,
    this.answer = '',
    this.createdAt,
    this.answeredAt,
  });

  final String id;
  final String uid;
  final String userName;
  final String title;
  final String message;

  /// 운영자의 답변 (아직 없으면 빈 문자열).
  final String answer;
  final DateTime? createdAt;
  final DateTime? answeredAt;

  bool get answered => answer.isNotEmpty;

  /// 제목 · 내용 · 답변 길이 제한. `firestore.rules`의 제한과 같아야 한다.
  static const maxTitle = 40;
  static const maxMessage = 1000;
  static const maxAnswer = 1000;

  factory Inquiry.fromDoc(DocumentSnapshot<Json> doc) {
    final d = doc.data() ?? const {};
    return Inquiry(
      id: doc.id,
      uid: d['uid'] as String? ?? '',
      userName: d['userName'] as String? ?? '',
      title: d['title'] as String? ?? '',
      message: d['message'] as String? ?? '',
      answer: d['answer'] as String? ?? '',
      createdAt: toDate(d['createdAt']),
      answeredAt: toDate(d['answeredAt']),
    );
  }
}
