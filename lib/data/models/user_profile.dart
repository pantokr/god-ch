import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_codec.dart';

/// 앱 가입 때 받은 회원 정보. 이름·전화번호와 개인정보 제3자 제공 동의 기록을 담는다.
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.name,
    required this.phone,
    required this.consentThirdParty,
    this.loginId,
    this.createdAt,
  });

  final String uid;

  /// 로그인 ID. Google로 가입한 회원은 없다.
  final String? loginId;
  final String name;
  final String phone;

  /// 개인정보 제3자(소속 교회) 제공 동의 여부.
  final bool consentThirdParty;
  final DateTime? createdAt;

  factory UserProfile.fromDoc(DocumentSnapshot<Json> doc) {
    final d = doc.data() ?? const {};
    return UserProfile(
      uid: doc.id,
      loginId: d['loginId'] as String?,
      name: d['name'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
      consentThirdParty: d['consentThirdParty'] as bool? ?? false,
      createdAt: toDate(d['createdAt']),
    );
  }
}
