import '../../../core/mvvm/view_model.dart';
import '../../../data/models/profile_field.dart';
import '../data/church_repository.dart';

/// 초대 코드로 교회 입장을 신청한다.
class JoinChurchViewModel extends ViewModel {
  JoinChurchViewModel(this._churches);

  final ChurchRepository _churches;

  /// 교회가 필수로 요청했는데 아직 입력하지 않은 정보. 비어 있지 않으면 입력란을 보여준다.
  Set<ProfileField> _missing = const {};
  String _missingChurch = '';

  Set<ProfileField> get missing => _missing;
  String get missingChurch => _missingChurch;

  /// 신청에 성공하면 true. 실패하면 [error]에 이유가 담긴다.
  /// 교회가 주소·생년월일을 요청하면 [missing]이 채워지고, 입력한 뒤 다시 부르면 된다.
  Future<bool> submit(
    String code, {
    String address = '',
    String birthDate = '',
  }) => run(() async {
    try {
      await _churches.requestJoinByCode(
        code,
        address: address,
        birthDate: birthDate,
      );
      _missing = const {};
    } on MissingProfileFields catch (e) {
      _missing = e.fields;
      _missingChurch = e.churchName;
      rethrow;
    }
  });
}
