import '../../../core/mvvm/view_model.dart';
import '../../../data/models/church_content.dart';
import '../data/content_repository.dart';

/// 갤러리 탭이 보여줄 사진첩 글들. 스트림은 한 번만 만들어 다시 그려도 재구독하지 않는다.
class GalleryViewModel extends ViewModel {
  GalleryViewModel(ContentRepository contents, String churchId)
    : albums = contents.latest(churchId, ContentKind.photo, limit: 100);

  final Stream<List<ChurchContent>> albums;
}
