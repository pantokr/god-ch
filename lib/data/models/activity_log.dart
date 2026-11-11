import 'package:cloud_firestore/cloud_firestore.dart';

/// 활동 기록을 묶는 갈래 (앱 운영자 > 활동 기록의 필터).
enum ActivityGroup {
  account('계정'),
  church('교회'),
  prayer('중보기도'),
  devotion('말씀묵상'),
  meeting('모임'),
  manage('관리');

  const ActivityGroup(this.label);

  final String label;
}

/// 기록하는 활동의 종류. [id]는 Firestore에 저장되는 값이고 `firestore.rules`의 허용 목록과 일치해야 한다.
/// 글 내용은 담지 않는다 (제목 정도만 [ActivityLog.summary]에 남긴다).
enum ActivityType {
  // 계정
  access('access', '접속', ActivityGroup.account),
  login('login', '로그인', ActivityGroup.account),
  logout('logout', '로그아웃', ActivityGroup.account),
  signUp('signUp', '회원가입', ActivityGroup.account),
  passwordChange('passwordChange', '비밀번호 변경', ActivityGroup.account),
  accountDelete('accountDelete', '앱 탈퇴', ActivityGroup.account),
  profileEdit('profileEdit', '내 정보 수정', ActivityGroup.account),
  // 교회
  joinRequest('joinRequest', '입장 신청', ActivityGroup.church),
  memberLeave('memberLeave', '교회 탈퇴', ActivityGroup.church),
  // 중보기도
  prayerCreate('prayerCreate', '중보기도 작성', ActivityGroup.prayer),
  prayerEdit('prayerEdit', '중보기도 수정', ActivityGroup.prayer),
  prayerDelete('prayerDelete', '중보기도 삭제', ActivityGroup.prayer),
  prayerRestore('prayerRestore', '중보기도 복구', ActivityGroup.prayer),
  prayerComment('prayerComment', '중보기도 댓글', ActivityGroup.prayer),
  privatePrayerView('privatePrayerView', '비공개 중보기도 열람', ActivityGroup.prayer),
  // 말씀묵상
  devotionCreate('devotionCreate', '말씀묵상 작성', ActivityGroup.devotion),
  devotionEdit('devotionEdit', '말씀묵상 수정', ActivityGroup.devotion),
  devotionDelete('devotionDelete', '말씀묵상 삭제', ActivityGroup.devotion),
  devotionReflection('devotionReflection', '말씀묵상 나눔', ActivityGroup.devotion),
  // 모임
  meetingCreate('meetingCreate', '모임 만들기', ActivityGroup.meeting),
  meetingEdit('meetingEdit', '모임 수정', ActivityGroup.meeting),
  meetingDelete('meetingDelete', '모임 삭제', ActivityGroup.meeting),
  meetingJoin('meetingJoin', '모임 참여', ActivityGroup.meeting),
  meetingLeave('meetingLeave', '모임 참여 취소', ActivityGroup.meeting),
  meetingComment('meetingComment', '모임 댓글', ActivityGroup.meeting),
  // 관리
  memberApprove('memberApprove', '입장 승인', ActivityGroup.manage),
  memberReject('memberReject', '입장 거절', ActivityGroup.manage),
  memberRemove('memberRemove', '추방', ActivityGroup.manage),
  memberRole('memberRole', '역할 변경', ActivityGroup.manage),
  memberBlock('memberBlock', '차단', ActivityGroup.manage),
  positionChange('positionChange', '직급 변경', ActivityGroup.manage),
  affiliationChange('affiliationChange', '소속 변경', ActivityGroup.manage);

  const ActivityType(this.id, this.label, this.group);

  final String id;
  final String label;
  final ActivityGroup group;

  /// 저장된 값으로 종류를 찾는다. 모르는 값이면 null.
  static ActivityType? fromId(String? id) {
    for (final t in values) {
      if (t.id == id) return t;
    }
    return null;
  }
}

/// 활동 기록 한 줄 (`activityLogs/{id}`). 한 번 쓰면 고치거나 지울 수 없다.
class ActivityLog {
  const ActivityLog({
    required this.id,
    required this.uid,
    required this.userName,
    required this.type,
    this.churchId = '',
    this.targetId = '',
    this.summary = '',
    this.at,
  });

  final String id;

  /// 활동한 회원.
  final String uid;

  /// 기록할 때의 이름 (나중에 이름이 바뀌어도 그대로다).
  final String userName;
  final ActivityType type;

  /// 활동이 일어난 교회. 계정 활동은 비어 있다.
  final String churchId;

  /// 대상 글 · 회원 · 모임의 ID.
  final String targetId;

  /// 짧은 설명 (모임 제목 · 변경 내용 등).
  final String summary;

  /// 기록된 시각. 서버 시각이 아직 정해지지 않았으면 null.
  final DateTime? at;

  static ActivityLog? fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data();
    final type = ActivityType.fromId(data['type'] as String?);
    if (type == null) return null;
    return ActivityLog(
      id: d.id,
      uid: data['uid'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      type: type,
      churchId: data['churchId'] as String? ?? '',
      targetId: data['targetId'] as String? ?? '',
      summary: data['summary'] as String? ?? '',
      at: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
