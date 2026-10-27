import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_codec.dart';

/// 교회 차단 목록의 한 사람. 차단되면 그 교회에 입장을 신청할 수 없다.
/// 문서 ID가 계정(uid)이다. 이름은 알 수 없으면 비어 있다.
class BlockedUser {
  const BlockedUser({
    required this.uid,
    required this.loginId,
    required this.name,
    this.createdAt,
    this.revoked = false,
  });

  final String uid;
  final String loginId;
  final String name;
  final DateTime? createdAt;

  /// 차단이 풀렸는가. 풀려도 기록은 남는다.
  final bool revoked;

  /// 목록에 보여줄 이름: 이름이 없으면 아이디.
  String get label => name.isNotEmpty ? name : loginId;

  factory BlockedUser.fromDoc(DocumentSnapshot<Json> doc) {
    final d = doc.data() ?? const {};
    return BlockedUser(
      uid: doc.id,
      loginId: d['loginId'] as String? ?? '',
      name: d['name'] as String? ?? '',
      createdAt: toDate(d['createdAt']),
      revoked: d['revoked'] == true,
    );
  }
}
