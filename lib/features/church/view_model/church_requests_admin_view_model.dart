import '../../../core/mvvm/view_model.dart';
import '../../../data/models/church_request.dart';
import '../data/church_request_repository.dart';

/// 앱 운영자 화면: 승인 대기 중인 교회 생성 요청을 승인하거나 거절한다.
class ChurchRequestsAdminViewModel extends ViewModel {
  ChurchRequestsAdminViewModel(this._requests)
    : pending = _requests.pendingRequests();

  final ChurchRequestRepository _requests;
  final Stream<List<ChurchRequest>> pending;

  Future<bool> approve(ChurchRequest r) => run(() => _requests.approve(r));

  Future<bool> reject(ChurchRequest r, String reason) =>
      run(() => _requests.reject(r, reason));
}
