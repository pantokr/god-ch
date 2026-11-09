import 'package:flutter/material.dart';

import '../../data/models/member.dart';
import '../../data/models/position.dart';
import '../icons.dart';
import '../position_style.dart';
import '../theme.dart';

/// 이름 앞의 아이콘: 교회 관리자는 왕관, 직급이 있으면 그 직급의 아이콘과 색,
/// 직급이 없으면 역할(교역자 · 회원)의 기본 모양, 그것도 없으면 사람 아이콘.
/// 사람 이름이 나오는 모든 목록 · 프로필이 같은 아이콘 규칙을 쓴다.
class MemberMark extends StatelessWidget {
  const MemberMark({
    super.key,
    required this.role,
    this.position,
    this.roles = RolePermissions.defaults,
    this.size = 18,
  });

  final Role role;

  /// 이 사람이 가진 직급 (모르면 null).
  final Position? position;

  /// 교회가 기본 직급(교역자 · 회원)에 정한 모양.
  final RolePermissions roles;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (role == Role.admin) {
      return Tooltip(
        message: '교회 관리자',
        child: Icon(AppIcons.crown, size: size, color: AppColors.crown),
      );
    }
    final p = position;
    if (p != null) {
      return Tooltip(
        message: p.name,
        child: Icon(
          PositionStyle.iconOf(p.icon),
          size: size,
          color: PositionStyle.colorOf(p.color),
        ),
      );
    }
    if (role == Role.staff) {
      final st = roles.styleOf(BuiltInPosition.staff);
      return Tooltip(
        message: '교역자',
        child: Icon(
          PositionStyle.iconOf(st.icon),
          size: size,
          color: PositionStyle.colorOf(st.color),
        ),
      );
    }
    final st = roles.memberStyle;
    return Tooltip(
      message: '회원',
      child: Icon(
        st == null ? AppIcons.user : PositionStyle.iconOf(st.icon),
        size: size,
        color: st == null
            ? context.palette.muted
            : PositionStyle.colorOf(st.color),
      ),
    );
  }
}
