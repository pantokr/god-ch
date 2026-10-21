class ReactionType {
  const ReactionType(this.id, this.emoji, this.label);

  final String id;
  final String emoji;
  final String label;
}

/// firestore.rules의 허용 목록과 반드시 일치해야 한다.
const reactionTypes = [
  ReactionType('pray', '🙏', '함께 기도해요'),
  ReactionType('love', '❤️', '사랑해요'),
  ReactionType('cheer', '💪', '힘내세요'),
  ReactionType('peace', '🕊️', '평안을 빌어요'),
];

/// 이모티콘별 개수와 내가 누른 이모티콘. 누른 사람의 정보는 담지 않는다.
class ReactionSummary {
  const ReactionSummary(this.counts, this.mine);

  static const empty = ReactionSummary({}, {});

  final Map<String, int> counts;
  final Set<String> mine;

  int get total => counts.values.fold(0, (a, b) => a + b);
}
