import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_codec.dart';

enum RequestStatus { pending, approved, rejected }

/// 교회 생성 요청. 앱 운영자가 승인하면 같은 ID로 교회가 만들어지고, 요청자가 첫 관리자가 된다.
class ChurchRequest {
  const ChurchRequest({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.requesterEmail,
    this.requesterPhone = '',
    required this.name,
    required this.phone,
    required this.address,
    required this.status,
    this.rejectReason,
    this.createdAt,
  });

  final String id;
  final String requesterId;
  final String requesterName;
  final String requesterEmail;
  final String requesterPhone;

  /// 교회 이름.
  final String name;

  /// 교회 전화번호 (예: 02-1234-5678).
  final String phone;

  /// 도로명 주소.
  final String address;
  final RequestStatus status;
  final String? rejectReason;
  final DateTime? createdAt;

  factory ChurchRequest.fromDoc(DocumentSnapshot<Json> doc) {
    final d = doc.data() ?? const {};
    return ChurchRequest(
      id: doc.id,
      requesterId: d['requesterId'] as String? ?? '',
      requesterName: d['requesterName'] as String? ?? '',
      requesterEmail: d['requesterEmail'] as String? ?? '',
      requesterPhone: d['requesterPhone'] as String? ?? '',
      name: d['name'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
      address: d['address'] as String? ?? '',
      status: enumByName(
        RequestStatus.values,
        d['status'],
        RequestStatus.pending,
      ),
      rejectReason: d['rejectReason'] as String?,
      createdAt: toDate(d['createdAt']),
    );
  }
}
