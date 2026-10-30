import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_codec.dart';

/// Firestore 컬렉션 경로를 한곳에 모았다. 모든 교회 데이터는 churches/{churchId} 아래에 있다.
class FirestorePaths {
  const FirestorePaths(this.db);

  final FirebaseFirestore db;

  CollectionReference<Json> get churches => db.collection('churches');

  /// 교회 생성 요청. 승인되면 같은 ID로 churches 문서가 만들어진다.
  CollectionReference<Json> get churchRequests =>
      db.collection('churchRequests');

  /// 앱 운영자 계정. 문서는 Firebase 콘솔에서만 만든다.
  CollectionReference<Json> get admins => db.collection('admins');

  /// 초대 코드 → 교회 연결. 문서 ID가 코드 자체다.
  CollectionReference<Json> get inviteCodes => db.collection('inviteCodes');

  DocumentReference<Json> church(String churchId) => churches.doc(churchId);

  CollectionReference<Json> members(String churchId) =>
      church(churchId).collection('members');

  /// 차단 목록: 문서 ID가 차단된 계정(uid).
  CollectionReference<Json> blocked(String churchId) =>
      church(churchId).collection('blocked');

  CollectionReference<Json> affiliations(String churchId) =>
      church(churchId).collection('affiliations');

  /// 기도 요청 글. 문서 ID가 시간 역순이라 이름순이 곧 최신순이다 ([PrayerRepository.newId]).
  CollectionReference<Json> prayers(String churchId) =>
      church(churchId).collection('prayers');

  /// 말씀묵상 글. 아래에 교인의 묵상 글 `reflections/{uid}`가 있다.
  CollectionReference<Json> devotions(String churchId) =>
      church(churchId).collection('devotions');

  /// 모임. 모임장 · 정원 · 참여자 · 좋아요 · 조회수를 한 문서에 둔다.
  CollectionReference<Json> meetings(String churchId) =>
      church(churchId).collection('meetings');

  CollectionReference<Json> accessLogs(String churchId) =>
      church(churchId).collection('accessLogs');

  /// 모든 교회의 members 문서 (내 소속 교회 조회용 collection group).
  Query<Json> get allMembers => db.collectionGroup('members');
}
