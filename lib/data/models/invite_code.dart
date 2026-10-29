import 'member.dart';

/// 교회의 초대 코드. 코드를 만들 때 정한 역할을 담고 있어서, 이 코드로 입장을 신청하면
/// 그 역할로 신청된다. 유효기간이 지나면 입장 신청에 쓸 수 없다.
class InviteCode {
  const InviteCode(
    this.code,
    this.expiresAt, {
    this.role = Role.member,
    this.singleUse = false,
  });

  final String code;
  final DateTime expiresAt;

  /// 이 코드로 들어오는 사람의 역할. 교인 또는 교역자.
  final Role role;

  /// 일회용: 누군가 이 코드로 입장을 신청하면 코드가 사라진다.
  final bool singleUse;

  bool get isExpired => !expiresAt.isAfter(DateTime.now());
}
