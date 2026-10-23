import 'dart:typed_data';

import '../../../core/mvvm/view_model.dart';
import '../../../data/models/church_content.dart';
import '../data/content_repository.dart';

/// 한 종류의 콘텐츠 전체 목록 ("더보기")과, 관리 화면에서의 추가·수정·삭제.
class ContentListViewModel extends ViewModel {
  ContentListViewModel(this._repository, this.churchId, this.kind)
    : items = _repository.latest(churchId, kind);

  final ContentRepository _repository;
  final String churchId;
  final ContentKind kind;
  final Stream<List<ChurchContent>> items;

  Future<bool> save({
    String? id,
    required String title,
    required String body,
    required DateTime date,
    List<String> imageUrls = const [],
    String videoUrl = '',
  }) => run(
    () => _repository.save(
      churchId,
      kind,
      id: id,
      title: title,
      body: body,
      date: date,
      imageUrls: imageUrls,
      videoUrl: videoUrl,
    ),
  );

  Future<bool> delete(String id) =>
      run(() => _repository.delete(churchId, kind, id));

  /// 이미지를 올리고 다운로드 주소를 돌려준다. 실패하면 null이고 [error]에 이유가 남는다.
  Future<String?> uploadImage(String fileName, Uint8List bytes) async {
    String? url;
    await run(() async {
      url = await _repository.uploadImage(
        churchId,
        kind,
        fileName: fileName,
        bytes: bytes,
      );
    });
    return url;
  }
}
