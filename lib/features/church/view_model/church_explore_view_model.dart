import '../../../core/mvvm/view_model.dart';
import '../../../data/models/church.dart';
import '../../../data/models/member.dart';
import '../../../data/models/profile_field.dart';
import '../data/church_repository.dart';

/// 교회 탐색: 공개 탐색에 노출된 교회를 찾아 입장을 요청한다. 스트림은 한 번만 만든다.
class ChurchExploreViewModel extends ViewModel {
  ChurchExploreViewModel(this._churches)
    : churches = _churches.publicChurches(),
      memberships = _churches.myMemberships();

  final ChurchRepository _churches;

  /// 공개 탐색에 노출된 교회들.
  final Stream<List<Church>> churches;

  /// 내가 속하거나 요청한 교회들 (요청 상태를 보여주려고).
  final Stream<List<Member>> memberships;

  String _query = '';

  String get query => _query;

  void setQuery(String v) {
    _query = v.trim();
    notifyListeners();
  }

  /// 이름이나 지역(시도 시군구)에 검색어가 들어 있는 교회만. 상세 주소로는 찾지 않는다.
  List<Church> filter(List<Church> all) {
    if (_query.isEmpty) return all;
    final q = _query.toLowerCase();
    return all
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.region.toLowerCase().contains(q),
        )
        .toList();
  }

  /// 교회가 입장 시 필수로 요청했는데 아직 없는 정보. 비어 있지 않으면 입력받고 다시 요청한다.
  Set<ProfileField> _missing = const {};

  Set<ProfileField> get missing => _missing;

  /// 입장을 요청한다. 성공하면 true. 필수 정보가 모자라면 false이고 [missing]이 채워진다.
  Future<bool> request(
    Church church, {
    String address = '',
    String birthDate = '',
  }) => run(() async {
    try {
      await _churches.requestJoinPublic(
        church,
        address: address,
        birthDate: birthDate,
      );
      _missing = const {};
    } on MissingProfileFields catch (e) {
      _missing = e.fields;
      rethrow;
    }
  });
}
