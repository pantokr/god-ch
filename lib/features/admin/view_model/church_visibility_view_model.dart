import '../../../core/mvvm/view_model.dart';
import '../../church/data/church_repository.dart';

/// 교회 노출 설정: 공개 탐색에 노출할지 비공개(초대 코드로만 입장)로 둘지. 스트림은 한 번만 만든다.
class ChurchVisibilityViewModel extends ViewModel {
  ChurchVisibilityViewModel(this._churches, this._churchId)
    : listed = _churches.isListed(_churchId);

  final ChurchRepository _churches;
  final String _churchId;

  /// 공개 탐색에 노출되는가.
  final Stream<bool> listed;

  Future<bool> setListed(bool value) =>
      run(() => _churches.setListed(_churchId, value));
}
