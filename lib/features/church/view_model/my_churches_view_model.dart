import '../../../core/mvvm/view_model.dart';
import '../../../data/models/church_request.dart';
import '../../../data/models/member.dart';
import '../../auth/data/auth_repository.dart';
import '../data/church_repository.dart';
import '../data/church_request_repository.dart';

/// 내 교회 목록 화면: 소속·신청한 교회와 교회 생성 요청 현황.
class MyChurchesViewModel extends ViewModel {
  MyChurchesViewModel(
    this._churches,
    ChurchRequestRepository requests,
    this._auth,
  ) : memberships = _churches.myMemberships(),
      myRequests = requests.myRequests();

  final ChurchRepository _churches;
  final AuthRepository _auth;

  /// 내가 속하거나 신청한 모든 교회. 한 번만 만들어 화면이 다시 그려져도 재구독하지 않는다.
  final Stream<List<Member>> memberships;

  /// 내가 보낸 교회 생성 요청.
  final Stream<List<ChurchRequest>> myRequests;

  /// 마지막으로 들어간 교회의 ID.
  Future<String?> lastChurchId() => _churches.lastChurchId();

  String get userName => _auth.displayName;

  Future<void> signOut() => _auth.signOut();
}
