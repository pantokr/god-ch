/// 입장 · 탈퇴 기록 한 줄의 종류.
enum MembershipEventKind {
  requested('입장 신청'),
  joined('입장'),
  left('탈퇴'),
  removed('추방');

  const MembershipEventKind(this.label);

  final String label;
}

/// 누가 언제 입장하고 탈퇴했는지 보여 주는 기록 한 줄. 교인 문서(`members`)의 가입 · 탈퇴 시각에서 만들어진다
/// (교인 문서는 지우지 않고 남기므로 탈퇴한 사람도 기록에 있다).
class MembershipEvent {
  const MembershipEvent({
    required this.uid,
    required this.name,
    required this.kind,
    this.loginId = '',
    this.at,
    this.by = '',
  });

  final String uid;
  final String name;
  final String loginId;
  final MembershipEventKind kind;

  /// 일어난 시각. 서버 시각이 아직 정해지지 않았으면 null.
  final DateTime? at;

  /// 탈퇴 · 추방을 한 사람의 uid (본인이면 탈퇴, 다른 사람이면 추방).
  final String by;
}
