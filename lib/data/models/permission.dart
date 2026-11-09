/// 권한 묶음 이름.
enum PermissionGroup {
  people('인원'),
  meeting('일정'),
  meetingJoin('일정 참여'),
  prayer('중보기도'),
  devotion('말씀묵상'),
  fixed('관리자 고정');

  const PermissionGroup(this.label);

  final String label;
}

/// 권한 소분류: 목록에서 묶음 안을 조회 · 생성 · 삭제 · 관리로 나누어 보여준다.
enum PermissionKind {
  view('조회'),
  create('생성'),
  delete('삭제'),
  manage('관리');

  const PermissionKind(this.label);

  final String label;
}

/// 이 앱의 권한 목록. 교회 관리자는 모두 가지고(절대 권한), 교역자 · 회원 · 직급은 아래 기본값과 교회가 정한 값을 따른다.
///
/// - [grantable]이 true인 권한은 교역자 · 회원 기본 직급과 직접 만든 직급에 담아 줄 수 있다.
///   직급의 권한은 교인 문서의 `permissions`에 복사되고, `firestore.rules`의 `can()`이 같은 기준으로 막는다.
///   이 목록은 `firestore.rules`의 `delegable()`과 같아야 한다.
/// - [staffDefault] · [memberDefault]는 교회가 따로 정하지 않았을 때 교역자 · 회원이 갖는 권한이다
///   (규칙의 `delegable()` · `memberDefaults()`와 같아야 한다).
/// - [grantable]이 false인 권한은 역할(교회 관리자 · 교역자)로만 정해지고 직급으로 줄 수 없다.
enum Permission {
  // ---- 인원 ----
  memberManage(
    'member.manage',
    '인원 관리',
    PermissionGroup.people,
    staffDefault: true,
  ),
  affiliationEdit('affiliation.edit', '소속 만들기·삭제', PermissionGroup.people),

  // ---- 중보기도 ----
  // 범위: 전체 = 타인의 글 · 댓글까지, 본인만 = 본인이 쓴 것만.
  prayerPost(
    'prayer.post',
    '글 관리',
    PermissionGroup.prayer,
    staffDefault: true,
    memberDefault: true,
    memberOwnOnly: true,
  ),
  prayerEngage(
    'prayer.engage',
    '반응 · 댓글 관리',
    PermissionGroup.prayer,
    staffDefault: true,
    memberDefault: true,
    memberOwnOnly: true,
  ),
  prayerPrivate(
    'prayer.private',
    '비공개 글 조회',
    PermissionGroup.prayer,
    staffDefault: true,
  ),

  // ---- 말씀묵상 ----
  devotionPost(
    'devotion.post',
    '글 관리',
    PermissionGroup.devotion,
    staffDefault: true,
  ),
  devotionEngage(
    'devotion.engage',
    '반응 · 댓글 관리',
    PermissionGroup.devotion,
    staffDefault: true,
    memberDefault: true,
    memberOwnOnly: true,
  ),
  devotionPrivate(
    'devotion.private',
    '비공개 글 조회',
    PermissionGroup.devotion,
    staffDefault: true,
  ),

  // ---- 일정 ----
  meetingManage(
    'meeting.manage',
    '일정 관리',
    PermissionGroup.meeting,
    staffDefault: true,
  ),
  meetingParticipants(
    'meeting.participants',
    '참여자 관리',
    PermissionGroup.meeting,
    staffDefault: true,
  ),
  meetingJoin(
    'meeting.join',
    '일정 참여',
    PermissionGroup.meetingJoin,
    staffDefault: true,
    memberDefault: true,
  ),

  // ---- 관리자 고정 (직급으로 줄 수 없다) ----
  memberRole(
    'member.role',
    '교인 역할 변경 · 내보내기',
    PermissionGroup.fixed,
    grantable: false,
  ),
  affiliationManage(
    'affiliation.manage',
    '소속 만들기 · 이름 변경 · 소속별 기능 허용',
    PermissionGroup.fixed,
    grantable: false,
  ),
  positionManage(
    'position.manage',
    '직급 만들기 · 수정 · 삭제 · 권한 부여',
    PermissionGroup.fixed,
    grantable: false,
  ),
  prayerModerate(
    'prayer.moderate',
    '중보기도 타인 글 수정 · 교역자 응답 (교역자 이상)',
    PermissionGroup.fixed,
    grantable: false,
    staffDefault: true,
  ),
  settings(
    'settings',
    '중보기도 · 말씀묵상 · 모임 일정 설정',
    PermissionGroup.fixed,
    grantable: false,
  ),
  churchInfo(
    'church.info',
    '교회 정보 수정 · 폐쇄 요청',
    PermissionGroup.fixed,
    grantable: false,
  );

  const Permission(
    this.key,
    this.label,
    this.group, {
    this.grantable = true,
    this.staffDefault = false,
    this.memberDefault = false,
    this.memberOwnOnly = false,
  });

  /// 저장되는 이름 (`firestore.rules`와 같다).
  final String key;
  final String label;
  final PermissionGroup group;

  /// 직급으로 줄 수 있는가.
  final bool grantable;

  /// 교회가 따로 정하지 않았을 때 교역자가 갖는가.
  final bool staffDefault;

  /// 교회가 따로 정하지 않았을 때 회원이 갖는가 (지금까지 회원이 하던 일).
  final bool memberDefault;

  /// 교인 기본 직급이 이 권한을 "본인만"(본인이 쓴 것만) 범위로 갖는가. 정한 적이 없을 때의 교인 기본이다.
  final bool memberOwnOnly;

  /// 범위(전체 · 본인만)가 뜻이 있는가: 타인의 것까지 다루느냐 본인 것만 다루느냐가 갈리는 권한이다
  /// (글 · 반응 · 댓글 · 일정 · 참여자 관리). 그 밖의 권한(비공개 글 조회 · 일정 참여 · 인원 관리 ·
  /// 소속 만들기 · 삭제)은 쓰거나 못 쓰거나 둘뿐이다.
  bool get scoped => switch (this) {
    prayerPost ||
    prayerEngage ||
    devotionPost ||
    devotionEngage ||
    meetingManage ||
    meetingParticipants => true,
    _ => false,
  };

  /// 이름 아래에 작게 보이는 한 줄 설명: 이 권한으로 하는 일만 짧게 쓴다 (범위 · 비공개 여부는 옆의 체크 칸이 말해 준다).
  String get hint => switch (this) {
    memberManage => '입장 승인 · 초대 코드 · 소속 배치',
    prayerPost => '제목 작성 · 수정 · 삭제',
    prayerEngage => '반응 · 댓글 작성 · 삭제',
    prayerPrivate => '비공개 글 보기',
    devotionPost => '글 작성 · 수정 · 삭제',
    devotionEngage => '반응 · 댓글 작성 · 삭제',
    devotionPrivate => '비공개 글 보기',
    meetingManage => '일정 만들기 · 수정 · 삭제',
    meetingParticipants => '참여자 조회 · 승인 · 거절 · 추방',
    meetingJoin => '참여 신청',
    _ => '',
  };

  /// [keys] 안에 이 권한이 들어 있는가.
  bool inKeys(Iterable<String> keys) => keys.contains(key);

  /// 목록에서 어느 소분류에 놓이는가. 조회 · 생성(글 · 댓글 · 좋아요 · 참여) · 삭제 · 관리(인원 업무).
  PermissionKind get kind => switch (this) {
    prayerPost ||
    prayerEngage ||
    devotionPost ||
    devotionEngage ||
    meetingJoin => PermissionKind.create,
    prayerPrivate || devotionPrivate => PermissionKind.view,
    meetingManage => PermissionKind.delete,
    _ => PermissionKind.manage,
  };

  /// 이 권한이 켜지려면 먼저 켜져 있어야 하는 권한. 지금은 모든 권한이 서로 독립이라 늘 비어 있다
  /// (권한 목록은 들여쓰기 없이 평평하게 보이고, 하나를 켜고 꺼도 다른 권한은 바뀌지 않는다).
  List<Permission> get requires => const [];

  /// 선행 단계가 몇 겹인가 (목록에서 들여쓰는 칸 수).
  int get depth =>
      requires.isEmpty ? 0 : 1 + requires.map((r) => r.depth).reduce(_max);

  static int _max(int a, int b) => a > b ? a : b;

  /// 이 권한을 직접 · 간접으로 필요로 하는 권한들. 이 권한을 끄면 함께 꺼야 한다.
  Set<Permission> get dependents => {
    for (final p in values)
      if (p.requires.contains(this)) ...{p, ...p.dependents},
  };

  /// 선행 권한이 없는 권한을 걸러 낸 키 모음. 연쇄로 걸러지므로 결과는 항상 앞뒤가 맞는다.
  static Set<String> consistent(Iterable<String> keys) {
    final result = {...keys};
    var changed = true;
    while (changed) {
      changed = false;
      for (final p in values) {
        if (result.contains(p.key) &&
            p.requires.any((r) => !result.contains(r.key))) {
          result.remove(p.key);
          changed = true;
        }
      }
    }
    return result;
  }

  /// 직급으로 줄 수 있는 권한들.
  static List<Permission> get delegable => [
    for (final p in values)
      if (p.grantable) p,
  ];
}
