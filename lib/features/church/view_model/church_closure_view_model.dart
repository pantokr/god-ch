import '../../../core/mvvm/view_model.dart';
import '../../../data/models/church_closure_request.dart';
import '../data/church_closure_repository.dart';

/// 교회 운영자 화면: 이 교회의 폐쇄 요청 상태를 보고, 폐쇄를 요청한다.
class ChurchClosureViewModel extends ViewModel {
  ChurchClosureViewModel(this._closures, this._churchId, this._churchName)
    : latest = _closures.latestFor(_churchId);

  final ChurchClosureRepository _closures;
  final String _churchId;
  final String _churchName;

  /// 가장 최근 요청 (대기 중인 것이 있으면 그것). 요청한 적 없으면 null.
  final Stream<ChurchClosureRequest?> latest;

  Future<bool> request(String reason) => run(
    () => _closures.request(
      churchId: _churchId,
      churchName: _churchName,
      reason: reason,
    ),
  );
}

/// 앱 운영자 화면: 처리를 기다리는 폐쇄 요청을 승인하거나 거절한다.
class ChurchClosuresAdminViewModel extends ViewModel {
  ChurchClosuresAdminViewModel(this._closures) : pending = _closures.pending();

  final ChurchClosureRepository _closures;
  final Stream<List<ChurchClosureRequest>> pending;

  Future<bool> approve(ChurchClosureRequest r) =>
      run(() => _closures.approve(r));

  Future<bool> reject(ChurchClosureRequest r, String reason) =>
      run(() => _closures.reject(r, reason));
}
