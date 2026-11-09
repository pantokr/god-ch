/// 내가 댓글을 남긴 곳의 종류.
enum CommentTarget {
  meeting('모임 일정'),
  prayer('중보기도'),
  devotion('말씀묵상');

  const CommentTarget(this.label);

  final String label;
}

/// 내가 남긴 댓글 한 건과, 그 댓글이 달린 글(일정 · 중보기도 · 말씀묵상).
class MyComment {
  const MyComment({
    required this.target,
    required this.targetId,
    required this.text,
    required this.targetTitle,
    this.date,
  });

  final CommentTarget target;

  /// 댓글이 달린 글의 id (일정 · 중보기도 · 말씀).
  final String targetId;

  /// 댓글 내용.
  final String text;

  /// 댓글이 달린 글의 제목(중보기도는 글쓴이 이름). 읽을 수 없으면 비어 있다.
  final String targetTitle;
  final DateTime? date;
}
