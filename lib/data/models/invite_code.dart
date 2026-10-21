/// 교회의 초대 코드. 유효기간이 지나면 입장 신청에 쓸 수 없다.
class InviteCode {
  const InviteCode(this.code, this.expiresAt);

  final String code;
  final DateTime expiresAt;

  bool get isExpired => !expiresAt.isAfter(DateTime.now());
}
