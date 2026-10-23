import 'member.dart';

/// 교회의 초대 코드. 코드를 만들 때 정한 역할·부서를 담고 있어서, 이 코드로 입장을 신청하면
/// 그 역할과 부서로 신청된다. 유효기간이 지나면 입장 신청에 쓸 수 없다.
class InviteCode {
  const InviteCode(
    this.code,
    this.expiresAt, {
    this.role = Role.member,
    this.departmentIds = const [],
    this.recipient = '',
  });

  final String code;
  final DateTime expiresAt;

  /// 이 코드로 들어오는 사람의 역할. 교인 또는 교역자.
  final Role role;

  /// 이 코드로 들어오는 사람이 처음부터 소속될 부서.
  final List<String> departmentIds;

  /// 코드를 받을 사람 (알아보기 위한 이름표).
  final String recipient;

  bool get isExpired => !expiresAt.isAfter(DateTime.now());
}
