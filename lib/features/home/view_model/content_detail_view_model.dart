import '../../../core/mvvm/view_model.dart';
import '../../../data/models/church_content.dart';
import '../data/content_repository.dart';

/// 콘텐츠 한 건 보기.
class ContentDetailViewModel extends ViewModel {
  ContentDetailViewModel(
    ContentRepository repository,
    String churchId,
    ContentKind kind,
    String id,
  ) : content = repository.one(churchId, kind, id);

  final Stream<ChurchContent?> content;
}
