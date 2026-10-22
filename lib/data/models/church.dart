import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_codec.dart';

/// 등록된 교회. 앱 운영자 화면의 교회 등록 관리에서 쓴다.
class Church {
  const Church({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    this.createdAt,
  });

  final String id;
  final String name;

  /// 교회 전화번호. 앱 운영자가 직접 등록한 교회는 비어 있을 수 있다.
  final String phone;

  /// 도로명 주소.
  final String address;
  final DateTime? createdAt;

  factory Church.fromDoc(DocumentSnapshot<Json> doc) {
    final d = doc.data() ?? const {};
    return Church(
      id: doc.id,
      name: d['name'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
      address: d['address'] as String? ?? '',
      createdAt: toDate(d['createdAt']),
    );
  }
}
