import '../../../core/mvvm/view_model.dart';
import '../../../data/models/church_content.dart';
import '../../../data/models/page_layout.dart';
import '../../../data/models/prayer.dart';
import '../../../data/models/prayer_settings.dart';
import '../../prayers/data/prayer_repository.dart';
import '../data/content_repository.dart';

/// 페이지의 구조(블록) 하나가 보여줄 자료. 스트림은 한 번만 만들어 다시 그려도 재구독하지 않는다.
/// 콘텐츠를 보여주는 구조는 [content], 기도 요청 구조는 [prayers]를 쓴다.
class BlockViewModel extends ViewModel {
  BlockViewModel(
    ContentRepository contents,
    PrayerRepository prayerRepository,
    String churchId,
    BlockConfig block, {
    String? departmentId,
  }) : prayers = block.type == BlockType.prayer
           ? prayerRepository.publicFeed(churchId, departmentId: departmentId)
           : null,
       prayerSettings = block.type == BlockType.prayer
           ? prayerRepository.settings(churchId)
           : null,
       content = block.source.kind == null
           ? null
           : block.type == BlockType.schedule
           ? contents.eventsInMonth(churchId, DateTime.now())
           : contents.latest(churchId, block.source.kind!, limit: block.limit);

  final Stream<List<ChurchContent>>? content;

  /// 기도 요청 구조가 보여줄 공개 기도제목.
  final Stream<List<Prayer>>? prayers;

  /// 기도 요청 구조의 운영 설정 (쓸 수 있는 사람 등).
  final Stream<PrayerSettings>? prayerSettings;
}
