import '../../../core/mvvm/view_model.dart';
import '../../members/data/member_repository.dart';

/// 입장한 교회가 필수로 요청한 정보(주소 · 생년월일)를 채워 제출한다.
/// 이 교회의 내 교인 정보에만 저장되고, 내 프로필이나 다른 교회에는 저장되지 않는다.
class RequiredInfoViewModel extends ViewModel {
  RequiredInfoViewModel(this._members, this._churchId);

  final MemberRepository _members;
  final String _churchId;

  /// 비어 있는 항목은 제출하지 않는다. 성공하면 true.
  Future<bool> save({String address = '', String birthDate = ''}) => run(
    () => _members.submitJoinInfo(
      _churchId,
      address: address,
      birthDate: birthDate,
    ),
  );
}
