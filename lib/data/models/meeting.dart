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
    this.participantIds = const [],
    this.likedBy = const [],
    this.views = 0,
    this.deleted = false,
    this.createdAt,
  });

  /// 글자 수 제한 (`firestore.rules`와 같아야 한다).
  static const maxTitle = 60;
  static const maxDescription = 2000;
  static const maxPlace = 100;
  static const maxCapacity = 200;

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
  final List<String> participantIds;
  final List<String> likedBy;
  final int views;
  final bool deleted;
  final DateTime? createdAt;

  int get joined => participantIds.length;
  int get likes => likedBy.length;

  /// 남은 자리.
  int get seatsLeft => (capacity - joined).clamp(0, capacity);

  bool get isFull => joined >= capacity;

  /// 이미 지난 모임인가.
  bool get ended => date.isBefore(DateTime.now());

  bool joinedBy(String uid) => participantIds.contains(uid);

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
      participantIds: List<String>.from(
        d['participantIds'] as List? ?? const [],
      ),
      likedBy: List<String>.from(d['likedBy'] as List? ?? const []),
      views: (d['views'] as num?)?.toInt() ?? 0,
      deleted: d['deleted'] == true,
      createdAt: toDate(d['createdAt']),
    );
  }
}
