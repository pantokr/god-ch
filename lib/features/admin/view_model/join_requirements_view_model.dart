import '../../../core/mvvm/view_model.dart';
import '../../../data/models/profile_field.dart';
import '../../church/data/church_repository.dart';

/// 입장 시 필수 정보: 교회가 입장 신청에 필수로 요청하는 회원 정보를 읽고 바꾼다. 스트림은 한 번만 만든다.
class JoinRequirementsViewModel extends ViewModel {
  JoinRequirementsViewModel(this._churches, this._churchId)
    : requirements = _churches.joinRequirements(_churchId);

  final ChurchRepository _churches;
  final String _churchId;
  final Stream<Set<ProfileField>> requirements;

  /// [field]를 필수로 켜거나 끈다.
  Future<bool> toggle(Set<ProfileField> current, ProfileField field, bool on) =>
      run(
        () => _churches.setJoinRequirements(_churchId, {
          ...current.where((f) => f != field),
          if (on) field,
        }),
      );
}
