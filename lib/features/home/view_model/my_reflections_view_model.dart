import '../../../core/mvvm/view_model.dart';
import '../../../data/models/church_content.dart';
import '../../../data/models/devotion_reflection.dart';
import '../data/content_repository.dart';
import '../data/reflection_repository.dart';

/// 내가 쓴 말씀 묵상 한 건과, 그 묵상이 달린 말씀묵상 글.
class MyReflection {
  const MyReflection(this.devotion, this.reflection);

  final ChurchContent devotion;
  final DevotionReflection reflection;
}

/// 내 활동의 "내 묵상": 최근 말씀묵상 글들 중 내가 글을 남긴 것만 모은다. 스트림은 한 번만 만든다.
class MyReflectionsViewModel extends ViewModel {
  MyReflectionsViewModel(
    ContentRepository contents,
    ReflectionRepository reflections,
    String churchId,
  ) : items = contents.latest(churchId).asyncMap((devotions) async {
        final mine = <MyReflection>[];
        for (final d in devotions) {
          final r = await reflections.mine(churchId, d.id);
          if (r != null) mine.add(MyReflection(d, r));
        }
        return mine;
      });

  final Stream<List<MyReflection>> items;
}
