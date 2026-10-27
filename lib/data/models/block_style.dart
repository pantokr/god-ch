import 'dart:ui' show Color;

/// 색이 달라지는 구조(게시판의 글만 디자인 · 메신저 · 말씀묵상 · 일정)에서 고르는 스타일.
/// - simple: 평평한 면 + 얇은 테두리 + 고른 색은 포인트로만.
/// - pastel: 고른 색을 연하게 푼 면과 부드러운 그림자.
/// - neon: 고른 색으로 물든 어두운 그라데이션 면 + 빛나는 테두리.
enum BlockStyle {
  simple('simple', '심플'),
  pastel('pastel', '파스텔'),
  neon('neon', '네온');

  const BlockStyle(this.id, this.label);

  final String id;
  final String label;

  static BlockStyle fromId(String? id) =>
      values.firstWhere((s) => s.id == id, orElse: () => simple);
}

/// 스타일과 함께 고르는 색 팔레트 한 칸.
class BlockPalette {
  const BlockPalette(this.id, this.label, this.color);

  final String id;
  final String label;
  final Color color;

  static const all = [
    BlockPalette('indigo', '인디고', Color(0xFF5B5FEF)),
    BlockPalette('violet', '보라', Color(0xFF8B5CF6)),
    BlockPalette('rose', '장미', Color(0xFFEC4899)),
    BlockPalette('coral', '코랄', Color(0xFFFF6B5B)),
    BlockPalette('amber', '호박', Color(0xFFF59E0B)),
    BlockPalette('mint', '민트', Color(0xFF14B8A6)),
    BlockPalette('sky', '하늘', Color(0xFF0EA5E9)),
    BlockPalette('ink', '먹색', Color(0xFF1F2937)),
  ];

  static const defaultId = 'indigo';

  static BlockPalette byId(String? id) =>
      all.firstWhere((p) => p.id == id, orElse: () => all.first);
}
