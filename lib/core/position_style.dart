import 'package:flutter/material.dart';

import 'icons.dart';

/// 직급에 붙일 수 있는 아이콘과 색. 직급을 만들 때 고르고, 직급 카드와 회원 목록의 이름 옆에 보인다.
/// 저장되는 값은 아이콘의 키(문자열)와 색(ARGB 정수)이다 (`firestore.rules`가 형식을 검사한다).
class PositionStyle {
  PositionStyle._();

  static const defaultIcon = 'shield';

  /// 고를 수 있는 아이콘 (키 → 아이콘).
  static const icons = <String, IconData>{
    'shield': AppIcons.shieldCheck,
    'star': AppIcons.star,
    'crown': AppIcons.crown,
    'heart': AppIcons.handHeart,
    'flame': AppIcons.flame,
    'book': AppIcons.bookOpen,
    'music': AppIcons.music,
    'megaphone': AppIcons.megaphone,
    'flag': AppIcons.flag,
    'award': AppIcons.award,
    'sprout': AppIcons.sprout,
    'gem': AppIcons.gem,
    'handshake': AppIcons.handshake,
    'users': AppIcons.usersThree,
    'sparkles': AppIcons.sparkles,
    'church': AppIcons.church,
  };

  /// 고를 수 있는 색 (소프트 팔레트).
  static const colors = <int>[
    0xFF6C63FF, // 인디고
    0xFFFF6B6B, // 코랄
    0xFF2BB5A0, // 민트
    0xFFF2A33A, // 살구
    0xFFB06AD9, // 라벤더
    0xFF4A90E2, // 하늘
    0xFFE0558B, // 장미
    0xFF7A8794, // 회색
  ];

  static const defaultColor = 0xFF6C63FF;

  static IconData iconOf(String? key) => icons[key] ?? icons[defaultIcon]!;

  static Color colorOf(int? value) => Color(value ?? defaultColor);
}
