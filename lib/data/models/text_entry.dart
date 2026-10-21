/// 교역자 댓글 또는 비공개 글에 대한 교역자 답변 한 건.
class TextEntry {
  const TextEntry(this.id, this.content, this.createdAt);

  final String id;
  final String content;
  final DateTime? createdAt;
}
