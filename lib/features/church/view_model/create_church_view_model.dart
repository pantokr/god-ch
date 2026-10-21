import '../../../core/mvvm/view_model.dart';
import '../data/church_repository.dart';

/// 새 교회를 만든다. 성공하면 첫 초대 코드를 [createdCode]로 보여준다.
class CreateChurchViewModel extends ViewModel {
  CreateChurchViewModel(this._churches);

  final ChurchRepository _churches;

  String? _createdCode;

  String? get createdCode => _createdCode;

  Future<void> submit(String name) => run(() async {
    _createdCode = await _churches.createChurch(name);
  });
}
