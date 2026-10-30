/// 권한 묶음 이름.
enum PermissionGroup {
  people('인원'),
  prayer('중보기도'),
  devotion('말씀묵상'),
  meeting('일정'),
  fixed('관리자 고정');

  const PermissionGroup(this.label);

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
  memberApprove(
    'member.approve',
    '인원 승인 · 상태 변경',
    PermissionGroup.people,
    staffDefault: true,
  ),
  inviteManage(
    'invite.manage',
    '초대 코드 관리',
    PermissionGroup.people,
    staffDefault: true,
  ),
  affiliationAssign(
    'affiliation.assign',
    '소속 인원 배치',
    PermissionGroup.people,
    staffDefault: true,
  ),

  // ---- 중보기도 ----
  prayerWrite(
    'prayer.write',
    '글 작성',
    PermissionGroup.prayer,
    staffDefault: true,
    memberDefault: true,
  ),
  prayerViewPrivate(
    'prayer.viewPrivate',
    '비공개 조회',
    PermissionGroup.prayer,
    staffDefault: true,
  ),
  prayerInteract(
    'prayer.interact',
    '댓글 작성 · 좋아요',
    PermissionGroup.prayer,
    staffDefault: true,
    memberDefault: true,
  ),
  prayerCommentDeleteOwn(
    'prayer.commentDeleteOwn',
    '본인 댓글 삭제',
    PermissionGroup.prayer,
    staffDefault: true,
    memberDefault: true,
  ),
  prayerCommentDeleteOthers(
    'prayer.commentDeleteOthers',
    '타인 댓글 삭제',
    PermissionGroup.prayer,
    staffDefault: true,
  ),
  prayerDeleteOwn(
    'prayer.deleteOwn',
    '본인 글 삭제',
    PermissionGroup.prayer,
    staffDefault: true,
    memberDefault: true,
  ),
  prayerDeleteOthers(
    'prayer.deleteOthers',
    '타인 글 삭제',
    PermissionGroup.prayer,
    staffDefault: true,
  ),

  // ---- 말씀묵상 ----
  devotionWrite(
    'devotion.write',
    '글 작성',
    PermissionGroup.devotion,
    staffDefault: true,
  ),
  devotionViewPrivate(
    'devotion.viewPrivate',
    '비공개(소속 전용) 조회',
    PermissionGroup.devotion,
    staffDefault: true,
  ),
  devotionInteract(
    'devotion.interact',
    '댓글 작성 · 좋아요',
    PermissionGroup.devotion,
    staffDefault: true,
    memberDefault: true,
  ),
  devotionCommentDeleteOwn(
    'devotion.commentDeleteOwn',
    '본인 댓글 삭제',
    PermissionGroup.devotion,
    staffDefault: true,
    memberDefault: true,
  ),
  devotionCommentDeleteOthers(
    'devotion.commentDeleteOthers',
    '타인 댓글 삭제',
    PermissionGroup.devotion,
    staffDefault: true,
  ),
  devotionDeleteOwn(
    'devotion.deleteOwn',
    '본인 글 삭제',
    PermissionGroup.devotion,
    staffDefault: true,
  ),
  devotionDeleteOthers(
    'devotion.deleteOthers',
    '타인 글 삭제',
    PermissionGroup.devotion,
    staffDefault: true,
  ),

  // ---- 일정 ----
  meetingCreate(
    'meeting.create',
    '일정 생성',
    PermissionGroup.meeting,
    staffDefault: true,
  ),
  meetingDelete(
    'meeting.delete',
    '일정 삭제 (타인 일정 포함)',
    PermissionGroup.meeting,
    staffDefault: true,
  ),
  meetingJoin(
    'meeting.join',
    '일정 참여',
    PermissionGroup.meeting,
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
    '중보기도 설정 · 말씀묵상 설정',
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

  /// 이 권한이 켜지려면 먼저 켜져 있어야 하는 권한 (바로 앞 단계).
  /// 조회 → 작성 · 댓글 → 삭제처럼 아래 단계는 위 단계가 있어야 쓸 수 있다.
  /// 예: 본인 댓글 삭제는 댓글 작성이 있어야 하고, 타인 댓글 삭제는 본인 댓글 삭제가 있어야 한다.
  List<Permission> get requires => switch (this) {
    prayerCommentDeleteOwn => [prayerInteract],
    prayerCommentDeleteOthers => [prayerCommentDeleteOwn],
    prayerDeleteOwn => [prayerWrite],
    prayerDeleteOthers => [prayerDeleteOwn],
    devotionCommentDeleteOwn => [devotionInteract],
    devotionCommentDeleteOthers => [devotionCommentDeleteOwn],
    devotionDeleteOwn => [devotionWrite],
    devotionDeleteOthers => [devotionDeleteOwn],
    meetingDelete => [meetingCreate],
    affiliationAssign => [memberApprove],
    _ => const [],
  };

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

  static Permission? fromKey(String key) {
    for (final p in values) {
      if (p.key == key) return p;
    }
    return null;
  }
}
