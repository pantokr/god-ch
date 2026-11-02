import '../../../core/mvvm/view_model.dart';
import '../../../data/models/member.dart';
import '../../../data/models/membership_event.dart';
import '../../members/data/member_repository.dart';

/// 기록을 보는 범위: 전체 / 입장 / 탈퇴 · 추방.
enum MembershipLogFilter {
  all('전체'),
  joined('입장'),
  left('탈퇴 · 추방');

  const MembershipLogFilter(this.label);

  final String label;
}

/// 입장 · 탈퇴 기록. 스트림은 한 번만 만들고 거르기와 검색은 화면이 바로 한다.
class MembershipLogViewModel extends ViewModel {
  MembershipLogViewModel(MemberRepository members, Member me)
    : events = members.membershipLog(me.churchId);

  final Stream<List<MembershipEvent>> events;

  MembershipLogFilter _filter = MembershipLogFilter.all;
  String _query = '';

  MembershipLogFilter get filter => _filter;
  String get query => _query;

  void setFilter(MembershipLogFilter v) {
    if (_filter == v) return;
    _filter = v;
    notifyListeners();
  }

  void setQuery(String v) {
    _query = v.trim().toLowerCase();
    notifyListeners();
  }

  /// 고른 범위와 검색어(이름 · 아이디)에 맞는 기록.
  List<MembershipEvent> apply(List<MembershipEvent> all) => [
    for (final e in all)
      if (switch (_filter) {
            MembershipLogFilter.all => true,
            MembershipLogFilter.joined =>
              e.kind == MembershipEventKind.joined ||
                  e.kind == MembershipEventKind.requested,
            MembershipLogFilter.left =>
              e.kind == MembershipEventKind.left ||
                  e.kind == MembershipEventKind.removed,
          } &&
          (_query.isEmpty ||
              e.name.toLowerCase().contains(_query) ||
              e.loginId.toLowerCase().contains(_query)))
        e,
  ];
}
