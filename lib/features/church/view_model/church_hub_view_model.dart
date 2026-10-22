import '../../../core/mvvm/view_model.dart';
import '../../../data/models/church_request.dart';
import '../../../data/models/department.dart';
import '../../../data/models/member.dart';
import '../../auth/data/auth_repository.dart';
import '../data/church_repository.dart';
import '../data/church_request_repository.dart';

/// 로그인 직후의 메인 화면: 내 교회 목록, 교회 생성 요청 현황, 지금 들어가 있는 교회·부서.
class ChurchHubViewModel extends ViewModel {
  ChurchHubViewModel(
    ChurchRepository churches,
    ChurchRequestRepository requests,
    this._auth,
  ) : memberships = churches.myMemberships(),
      myRequests = requests.myRequests(),
      isPlatformAdmin = requests.isPlatformAdmin();

  final AuthRepository _auth;

  /// 내가 속하거나 신청한 모든 교회. 한 번만 만들어 화면이 다시 그려져도 재구독하지 않는다.
  final Stream<List<Member>> memberships;

  /// 내가 보낸 교회 생성 요청.
  final Stream<List<ChurchRequest>> myRequests;

  /// 내가 앱 운영자인가.
  final Stream<bool> isPlatformAdmin;

  String? _openChurchId;
  Department? _openDepartment;

  /// 들어가 있는 교회 (null이면 메인 화면).
  String? get openChurchId => _openChurchId;

  /// 들어가 있는 부서 (null이면 교회 전체).
  Department? get openDepartment => _openDepartment;

  String get userName => _auth.displayName;

  String get userEmail => _auth.email;

  Future<void> signOut() => _auth.signOut();

  void open(Member church, Department? department) {
    _openChurchId = church.churchId;
    _openDepartment = department;
    notifyListeners();
  }

  void leave() {
    _openChurchId = null;
    _openDepartment = null;
    notifyListeners();
  }
}
