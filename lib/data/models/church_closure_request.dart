import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_codec.dart';
import 'church_request.dart';

/// 교회 폐쇄 요청. 교회 운영자가 사유와 함께 요청하고, 앱 운영자가 승인하면 교회가 폐쇄 상태가 된다.
/// 승인해도 교회와 안의 기록은 지우지 않고 남긴다.
class ChurchClosureRequest {
  const ChurchClosureRequest({
    required this.id,
    required this.churchId,
    required this.churchName,
    required this.requesterId,
    required this.requesterName,
    required this.reason,
    required this.status,
    this.rejectReason,
    this.createdAt,
  });

  final String id;
  final String churchId;
  final String churchName;
  final String requesterId;
  final String requesterName;
  final String reason;
  final RequestStatus status;
  final String? rejectReason;
  final DateTime? createdAt;

  /// 사유 길이 제한. `firestore.rules`의 제한과 같아야 한다.
  static const maxReasonLength = 500;

  factory ChurchClosureRequest.fromDoc(DocumentSnapshot<Json> doc) {
    final d = doc.data() ?? const {};
    return ChurchClosureRequest(
      id: doc.id,
      churchId: d['churchId'] as String? ?? '',
      churchName: d['churchName'] as String? ?? '',
      requesterId: d['requesterId'] as String? ?? '',
      requesterName: d['requesterName'] as String? ?? '',
      reason: d['reason'] as String? ?? '',
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
