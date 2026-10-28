import 'dart:async';

import '../../../core/mvvm/view_model.dart';
import '../../../data/models/church_content.dart';
import '../data/content_repository.dart';

/// 콘텐츠 관리: 모든 종류의 글을 한꺼번에 모아 보여주고, 영역을 만들고 지우고, 글을 영역 사이로 옮긴다.
/// 종류마다 스트림을 한 번만 구독한다.
class ContentOverviewViewModel extends ViewModel {
  ContentOverviewViewModel(this._repository, this.churchId) {
    for (final k in ContentKind.values) {
      _subs.add(
        _repository
            .latest(churchId, k)
            .listen(
              (l) {
                _byKind[k] = l;
                notifyListeners();
              },
              onError: (Object _) {
                _byKind[k] = const [];
                notifyListeners();
              },
            ),
      );
    }
    _subs.add(
      _repository.areas(churchId).listen((a) {
        _registered = a;
        notifyListeners();
      }, onError: (Object _) {}),
    );
  }

  final ContentRepository _repository;
  final String churchId;
  final _subs = <StreamSubscription<Object?>>[];
  final _byKind = <ContentKind, List<ChurchContent>>{};
  List<ContentArea> _registered = const [];

  bool get loading => _byKind.length < ContentKind.values.length;

  /// 모든 종류의 글을 날짜가 최근인 순으로.
  List<ChurchContent> get all =>
      [for (final l in _byKind.values) ...l]
        ..sort((a, b) => b.date.compareTo(a.date));

  List<ChurchContent> postsOf(ContentKind kind) => _byKind[kind] ?? const [];

  /// [kind] 종류의 영역 이름들: 만들어 둔 영역과, 글에만 적혀 있던 이름. 이름순.
  List<String> areaNames(ContentKind kind) => {
    for (final a in _registered)
      if (a.kind == kind) a.name,
    for (final c in postsOf(kind))
      if (c.category.isNotEmpty) c.category,
  }.toList()..sort();

  /// 영역 [name]에 들어 있는 글 (영역 없음은 [name]이 빈 문자열).
  List<ChurchContent> postsIn(ContentKind kind, String name) => [
    for (final c in postsOf(kind))
      if (c.category == name) c,
  ];

  Future<bool> move(List<ChurchContent> items, String area) =>
      run(() => _repository.moveToArea(churchId, items, area));

  Future<bool> addArea(ContentKind kind, String name) => run(
    () => _repository.addArea(churchId, kind, name, existing: areaNames(kind)),
  );

  Future<bool> deleteArea(ContentKind kind, String name) =>
      run(() => _repository.deleteArea(churchId, kind, name));

  Future<bool> delete(ChurchContent c) =>
      run(() => _repository.delete(churchId, c.kind, c.id));

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}
