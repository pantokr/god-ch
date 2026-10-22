import '../../../core/mvvm/view_model.dart';
import '../../../data/models/church.dart';
import '../data/church_registry_repository.dart';

/// 앱 운영자의 교회 관리: 등록된 교회 목록과 직접 등록.
class ChurchRegistryViewModel extends ViewModel {
  ChurchRegistryViewModel(this._registry)
    // 두 탭이 같은 목록을 각자 구독하므로 여러 번 구독할 수 있게 한다.
    : churches = _registry.churches();

  /// 예시로 제공하는 교회 (노량진동 PL교회).
  static const sampleName = 'PL교회';
  static const sampleAddress = '서울 동작구 노들로2길 7 (노량진동)';

  final ChurchRegistryRepository _registry;
  final Stream<List<Church>> churches;

  Future<bool> register({
    required String name,
    required String phone,
    required String address,
  }) =>
      run(() => _registry.register(name: name, phone: phone, address: address));

  /// 예시 교회(PL교회)를 등록한다.
  Future<bool> registerSample() =>
      run(() => _registry.register(name: sampleName, address: sampleAddress));
}
