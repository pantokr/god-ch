import '../../../core/mvvm/view_model.dart';
import '../../../data/models/church_content.dart';
import '../../../data/models/devotion_reflection.dart';
import '../data/content_repository.dart';
import '../data/reflection_repository.dart';

/// 내가 쓴 댓글 한 건과, 그 댓글이 달린 말씀묵상 글.
class MyReflection {
  const MyReflection(this.devotion, this.reflection);

  final ChurchContent devotion;
  final DevotionReflection reflection;
}

/// 내 활동의 "내 묵상": 최근 말씀묵상 글들에 내가 단 댓글을 모은다 (한 글에 여러 개일 수 있다). 스트림은 한 번만 만든다.
class MyReflectionsViewModel extends ViewModel {
  MyReflectionsViewModel(
    ContentRepository contents,
    ReflectionRepository reflections,
    String churchId, {
    bool includePrivate = false,
  }) : items = contents
           .latest(churchId, includePrivate: includePrivate)
           .asyncMap((devotions) async {
             final mine = <MyReflection>[];
             for (final d in devotions) {
               for (final r in await reflections.mineAll(churchId, d.id)) {
                 mine.add(MyReflection(d, r));
               }
             }
             return mine;
           });

  final Stream<List<MyReflection>> items;
}
