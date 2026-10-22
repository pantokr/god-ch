import '../../../core/mvvm/view_model.dart';
import '../data/church_request_repository.dart';

/// 교회 생성을 요청한다. 앱 운영자가 승인하면 교회가 만들어진다.
class ChurchRequestViewModel extends ViewModel {
  ChurchRequestViewModel(this._requests);

  final ChurchRequestRepository _requests;

  bool _submitted = false;

  /// 요청을 보냈는가. 보낸 뒤에는 안내 문구를 보여준다.
  bool get submitted => _submitted;

  Future<void> submit({
    required String name,
    required String phone,
    required String address,
  }) async {
    final ok = await run(
      () => _requests.request(name: name, phone: phone, address: address),
    );
    if (ok) {
      _submitted = true;
      notifyListeners();
    }
  }
}
