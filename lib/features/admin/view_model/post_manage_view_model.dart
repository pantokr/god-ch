import '../../../core/app_exception.dart';
import '../../../core/mvvm/view_model.dart';
import '../../../data/models/department.dart';
import '../../../data/models/prayer.dart';
import '../../church/data/department_repository.dart';
import '../../members/data/member_repository.dart';
import '../../prayers/data/prayer_repository.dart';

/// 게시글 관리에서 살펴볼 수 있는 글의 종류: 모든 회원이 쓸 수 있는 곳.
/// 지금은 기도제목(메신저와 중보기도에 올라오는 글)뿐이다. 회원이 쓰는 곳이 늘면 여기에 더한다.
enum PostSource {
  prayers('중보기도 요청', '메신저와 중보기도에 올라오는 기도제목');

  const PostSource(this.label, this.description);

  final String label;
  final String description;
}

enum PostFilter { all, private, deleted }

/// 게시글 관리: 회원이 쓴 글을 모아 보고, 유해하거나 고쳐야 할 글을 수정·삭제·복구한다.
/// 비공개(교역자 전용) 글은 내용을 목록에 펼치지 않고, 수정할 수 없으며 삭제만 할 수 있다.
class PostManageViewModel extends ViewModel {
  PostManageViewModel(
    this._prayers,
    MemberRepository members,
    DepartmentRepository departments,
    this.churchId,
  ) : allPrayers = _prayers.allPrayers(churchId),
      authorNames = members
          .members(churchId)
          .map((list) => {for (final m in list) m.id: m.name}),
      departmentNames = departments
          .departments(churchId)
          .map((list) => {for (final Department d in list) d.id: d.name});

  final PrayerRepository _prayers;
  final String churchId;
  final Stream<List<Prayer>> allPrayers;

  /// 작성자 uid → 이름. 교역자만 볼 수 있다.
  final Stream<Map<String, String>> authorNames;
  final Stream<Map<String, String>> departmentNames;

  PostSource _source = PostSource.prayers;
  PostFilter _filter = PostFilter.all;
  String _query = '';

  PostSource get source => _source;
  PostFilter get filter => _filter;

  void setSource(PostSource v) {
    _source = v;
    notifyListeners();
  }

  void setFilter(PostFilter v) {
    _filter = v;
    notifyListeners();
  }

  void setQuery(String v) {
    _query = v.trim();
    notifyListeners();
  }

  bool matches(Prayer p, Map<String, String> names) {
    final inFilter = switch (_filter) {
      PostFilter.all => !p.deleted,
      PostFilter.private => !p.deleted && !p.isPublic,
      PostFilter.deleted => p.deleted,
    };
    if (!inFilter) return false;
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    // 비공개 글은 내용으로 찾지 않는다 (목록에서 내용을 보여주지 않기 때문).
    return p.title.toLowerCase().contains(q) ||
        (p.isPublic && p.content.toLowerCase().contains(q)) ||
        (names[p.authorId] ?? '').toLowerCase().contains(q);
  }

  Future<bool> edit(
    String id, {
    required String title,
    required String content,
  }) => run(() async {
    final t = title.trim();
    final c = content.trim();
    if (t.isEmpty || c.isEmpty) {
      throw const AppException('제목과 내용을 입력해 주세요.');
    }
    await _prayers.editByStaff(churchId, id, title: t, content: c);
  });

  Future<bool> delete(String id, String reason) =>
      run(() => _prayers.deleteByStaff(churchId, id, reason));

  Future<bool> restore(String id) => run(() => _prayers.restore(churchId, id));
}
