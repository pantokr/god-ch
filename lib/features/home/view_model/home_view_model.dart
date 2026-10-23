import '../../../core/mvvm/view_model.dart';
import '../../../data/models/church_content.dart';
import '../data/content_repository.dart';

/// 교회 메인 페이지: 공지 캐러셀과 일정·사진첩·설교영상·말씀묵상 미리보기.
/// 스트림은 한 번만 만들어 화면이 다시 그려져도 재구독하지 않는다.
class HomeViewModel extends ViewModel {
  HomeViewModel(ContentRepository repository, String churchId)
    : notices = repository.latest(churchId, ContentKind.notice, limit: 5),
      events = repository.upcomingEvents(churchId, limit: 4),
      photos = repository.latest(churchId, ContentKind.photo, limit: 6),
      sermons = repository.latest(churchId, ContentKind.sermon, limit: 3),
      devotions = repository.latest(churchId, ContentKind.devotion, limit: 1);

  final Stream<List<ChurchContent>> notices;
  final Stream<List<ChurchContent>> events;
  final Stream<List<ChurchContent>> photos;
  final Stream<List<ChurchContent>> sermons;
  final Stream<List<ChurchContent>> devotions;
}
