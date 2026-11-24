import '../../../core/mvvm/view_model.dart';
import '../../../data/models/affiliation.dart';
import '../../../data/models/member.dart';
import '../../../data/models/person_card.dart';
import '../../people/data/people_repository.dart';
import '../../church/data/church_repository.dart';
import '../../church/data/affiliation_repository.dart';

/// 내 정보에 보여줄 소속: 내가 속한 교회들과, 교회마다 내가 속한 소속들. 스트림은 한 번만 만든다.
class MyAffiliationsViewModel extends ViewModel {
  MyAffiliationsViewModel(
    ChurchRepository churches,
    this._affiliations,
    this._people,
  ) : memberships = churches.myMemberships();

  final AffiliationRepository _affiliations;
  final PeopleRepository _people;

  final _cards = <String, Stream<PersonCard?>>{};

  /// [churchId] 교회에서의 내 사람 카드 (생일 공개 여부). 교회마다 한 번만 구독한다.
  Stream<PersonCard?> cardOf(String churchId, String uid) =>
      _cards.putIfAbsent('$churchId/$uid', () => _people.card(churchId, uid));

  /// 내 생일을 다른 교인에게 보일지 정한다.
  Future<bool> setBirthPublic(String churchId, String uid, bool value) =>
      run(() => _people.setBirthPublic(churchId, uid, value), blocking: false);

  /// 내가 속하거나 요청한 모든 교회에서의 내 정보. 화면은 이 중 승인된 교회만 보여준다.
  final Stream<List<Member>> memberships;

  final _byChurch = <String, Stream<List<Affiliation>>>{};

  /// [churchId] 교회의 소속들 (이름을 보여주려고). 교회마다 한 번만 구독한다.
  Stream<List<Affiliation>> affiliationsOf(String churchId) => _byChurch
      .putIfAbsent(churchId, () => _affiliations.affiliations(churchId));
}
