import '../../../core/mvvm/view_model.dart';
import '../../../data/models/activity_log.dart';
import '../../../data/models/church.dart';
import '../../activity/data/activity_log_repository.dart';
import '../data/church_registry_repository.dart';

/// 앱 운영자 > 활동 기록: 회원별 접속 · 활동을 최근 순으로 본다.
/// 기록은 한 번에 [pageSize]줄씩 가져오고, 한 회원을 고르면 그 회원의 기록만 가져온다.
/// 스트림은 처음과 "더 보기" · 회원 고르기 때만 새로 만들고, 갈래 · 검색은 화면이 바로 거른다.
class ActivityLogViewModel extends ViewModel {
  ActivityLogViewModel(this._logs, ChurchRegistryRepository registry)
    : churches = registry.churches() {
    _reload();
  }

  final ActivityLogRepository _logs;

  /// 교회 ID를 이름으로 바꿔 보여 주기 위한 교회 목록.
  final Stream<List<Church>> churches;

  /// 한 번에 가져오는 줄 수. "더 보기"를 누를 때마다 이만큼 늘어난다.
  static const pageSize = 100;

  late Stream<List<ActivityLog>> _stream;
  int _limit = pageSize;
  ActivityGroup? _group;
  String _query = '';
  String? _focusUid;
  String _focusName = '';

  Stream<List<ActivityLog>> get logs => _stream;
  int get limit => _limit;
  ActivityGroup? get group => _group;
  String get query => _query;

  /// 한 회원의 기록만 보고 있을 때 그 회원 (없으면 null).
  String? get focusUid => _focusUid;
  String get focusName => _focusName;

  void _reload() {
    _stream = _focusUid == null
        ? _logs.recent(limit: _limit)
        : _logs.byUser(_focusUid!, limit: _limit);
  }

  void setGroup(ActivityGroup? v) {
    if (_group == v) return;
    _group = v;
    notifyListeners();
  }

  void setQuery(String v) {
    _query = v.trim().toLowerCase();
    notifyListeners();
  }

  /// 이 회원의 기록만 본다.
  void focusUser(String uid, String name) {
    if (_focusUid == uid) return;
    _focusUid = uid;
    _focusName = name;
    _limit = pageSize;
    _reload();
    notifyListeners();
  }

  /// 전체 기록으로 돌아간다.
  void clearFocus() {
    if (_focusUid == null) return;
    _focusUid = null;
    _focusName = '';
    _limit = pageSize;
    _reload();
    notifyListeners();
  }

  /// 더 오래된 기록을 [pageSize]줄 더 가져온다.
  void loadMore() {
    _limit += pageSize;
    _reload();
    notifyListeners();
  }

  /// 고른 갈래와 검색어(이름 · 종류 · 교회 · 설명)에 맞는 기록.
  List<ActivityLog> apply(
    List<ActivityLog> all,
    Map<String, String> churchNames,
  ) => [
    for (final l in all)
      if ((_group == null || l.type.group == _group) &&
          (_query.isEmpty ||
              l.userName.toLowerCase().contains(_query) ||
              l.type.label.toLowerCase().contains(_query) ||
              l.summary.toLowerCase().contains(_query) ||
              (churchNames[l.churchId] ?? '').toLowerCase().contains(_query)))
        l,
  ];
}
