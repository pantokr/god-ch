/// 교역자 댓글 또는 비공개 글에 대한 교역자 답변 한 건.
class TextEntry {
  const TextEntry(this.id, this.content, this.createdAt, {this.authorId = ''});

  final String id;

  /// 쓴 사람 (댓글만 있다). 본인 댓글 삭제 권한을 가릴 때 쓴다.
  final String authorId;
  final String content;
  final DateTime? createdAt;
}
