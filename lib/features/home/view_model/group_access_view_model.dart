import '../../../core/mvvm/view_model.dart';
import '../../../data/models/affiliation.dart';
import '../../church/data/affiliation_repository.dart';

/// 기도 · 말씀 탭의 접근 판단에 쓰는 자료: 이 교회의 소속들. 스트림은 한 번만 만든다.
class GroupAccessViewModel extends ViewModel {
  GroupAccessViewModel(AffiliationRepository affiliations, String churchId)
    : affiliations = affiliations.affiliations(churchId);

  final Stream<List<Affiliation>> affiliations;
}
