/// 교역자 댓글 또는 비공개 글에 대한 교역자 답변 한 건.
class TextEntry {
  const TextEntry(
    this.id,
    this.content,
    this.createdAt, {
    this.authorId = '',
    this.authorName = '',
    this.edited = false,
  });

  final String id;

  /// 쓴 사람 (댓글만 있다). 본인 댓글 삭제 권한을 가릴 때 쓴다.
  final String authorId;

  /// 쓴 사람의 이름 (댓글만 있다. 이름을 남기기 전의 댓글은 비어 있다).
  final String authorName;
  final String content;

  /// 쓴 뒤에 고친 댓글인가.
  final bool edited;
  final DateTime? createdAt;
}
