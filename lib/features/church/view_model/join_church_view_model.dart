import '../../../core/mvvm/view_model.dart';
import '../data/church_repository.dart';

/// 초대 코드로 교회 입장을 신청한다.
class JoinChurchViewModel extends ViewModel {
  JoinChurchViewModel(this._churches);

  final ChurchRepository _churches;

  /// 신청에 성공하면 true. 실패하면 [error]에 이유가 담긴다.
  Future<bool> submit(String code) =>
      run(() => _churches.requestJoinByCode(code));
}
