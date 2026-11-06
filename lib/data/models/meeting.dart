import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_codec.dart';

/// 교회 모임 한 건. 모임장이 만들고 교인이 참여를 신청한다.
/// 참여자는 [participantIds](uid)에 담기고, [capacity]를 넘을 수 없다 (`firestore.rules`가 막는다).
/// 조회수([views])와 좋아요([likedBy])도 함께 저장된다.
class Meeting {
  const Meeting({
    required this.id,
    required this.title,
    required this.description,
    required this.place,
    required this.date,
    required this.capacity,
    required this.leaderId,
    required this.leaderName,
    this.imageUrl = '',
    this.participantIds = const [],
    this.pendingIds = const [],
    this.fee = 0,
    this.needsApproval = false,
    this.likedBy = const [],
    this.views = 0,
    this.deleted = false,
    this.createdAt,
    this.affiliationId,
  });

  /// 글자 수 제한 (`firestore.rules`와 같아야 한다).
  static const maxTitle = 24;
  static const maxDescription = 2000;
  static const maxPlace = 8;
  static const maxCapacity = 200;

  /// 회비 상한 (원, `firestore.rules`와 같아야 한다).
  static const maxFee = 10000000;

  final String id;
  final String title;
  final String description;
  final String place;

  /// 모임이 열리는 날짜와 시각.
  final DateTime date;

  /// 정원 (모임장 포함).
  final int capacity;
  final String leaderId;
  final String leaderName;

  /// 카드에 보이는 썸네일 주소. 없으면 빈 글자.
  final String imageUrl;
  final List<String> participantIds;

  /// 모임장의 승인을 기다리는 참여 신청자 (uid). 입장 조건이 모임장 승인일 때만 쓴다.
  final List<String> pendingIds;

  /// 회비 (원). 0이면 무료.
  final int fee;

  /// 입장 조건: true이면 참여 신청을 모임장이 승인해야 참여자가 된다.
  final bool needsApproval;
  final List<String> likedBy;
  final int views;
  final bool deleted;
  final DateTime? createdAt;

  /// 공개 범위: 이 소속의 교인만 참여할 수 있다. null이면 교회 전체.
  final String? affiliationId;

  int get joined => participantIds.length;
  int get likes => likedBy.length;

  /// 남은 자리.
  int get seatsLeft => (capacity - joined).clamp(0, capacity);

  bool get isFull => joined >= capacity;

  /// 이미 지난 모임인가.
  bool get ended => date.isBefore(DateTime.now());

  /// 이 교인이 참여할 수 있는 공개 범위인가 (교역자 이상은 어느 범위든 된다).
  bool openTo({required bool isStaff, required List<String> affiliationIds}) =>
      affiliationId == null ||
      isStaff ||
      affiliationIds.contains(affiliationId);

  bool joinedBy(String uid) => participantIds.contains(uid);

  /// 승인을 기다리는 중인가.
  bool pendingBy(String uid) => pendingIds.contains(uid);

  bool get isFree => fee <= 0;

  bool likedByUser(String uid) => likedBy.contains(uid);

  factory Meeting.fromDoc(DocumentSnapshot<Json> doc) {
    final d = doc.data() ?? const {};
    return Meeting(
      id: doc.id,
      title: d['title'] as String? ?? '',
      description: d['description'] as String? ?? '',
      place: d['place'] as String? ?? '',
      date: toDate(d['date']) ?? DateTime.now(),
      capacity: (d['capacity'] as num?)?.toInt() ?? 1,
      leaderId: d['leaderId'] as String? ?? '',
      leaderName: d['leaderName'] as String? ?? '',
      imageUrl: d['imageUrl'] as String? ?? '',
      participantIds: List<String>.from(
        d['participantIds'] as List? ?? const [],
      ),
      pendingIds: List<String>.from(d['pendingIds'] as List? ?? const []),
      fee: (d['fee'] as num?)?.toInt() ?? 0,
      needsApproval: d['needsApproval'] == true,
      likedBy: List<String>.from(d['likedBy'] as List? ?? const []),
      views: (d['views'] as num?)?.toInt() ?? 0,
      deleted: d['deleted'] == true,
      createdAt: toDate(d['createdAt']),
      affiliationId: d['affiliationId'] as String?,
    );
  }
}
