import 'dart:typed_data';

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

  String _query = '';

  String get query => _query;

  void setQuery(String value) {
    _query = value.trim().toLowerCase();
    notifyListeners();
  }

  /// 교회 이름·주소·전화번호 중 하나라도 검색어를 포함하면 보여준다 (회원 관리와 같은 방식).
  bool matches(Church c) {
    if (_query.isEmpty) return true;
    final digits = _query.replaceAll(RegExp(r'\D'), '');
    return c.name.toLowerCase().contains(_query) ||
        c.address.toLowerCase().contains(_query) ||
        (digits.isNotEmpty && c.phone.replaceAll('-', '').contains(digits));
  }

  Future<bool> register({
    required String name,
    required String phone,
    required String address,
  }) =>
      run(() => _registry.register(name: name, phone: phone, address: address));

  Future<bool> update(
    String churchId, {
    required String name,
    required String phone,
    required String address,
    String thumbnailUrl = '',
  }) => run(
    () => _registry.updateChurch(
      churchId,
      name: name,
      phone: phone,
      address: address,
      thumbnailUrl: thumbnailUrl,
    ),
  );

  /// 썸네일을 올린다. 성공하면 주소, 실패하면 null ([error]에 이유).
  Future<String?> uploadThumbnail(
    String churchId,
    String fileName,
    Uint8List bytes,
  ) async {
    String? url;
    await run(
      () async => url = await _registry.uploadChurchThumbnail(
        churchId,
        fileName,
        bytes,
      ),
    );
    return url;
  }

  /// 예시 교회(PL교회)를 등록한다.
  Future<bool> registerSample() => run(
    () => _registry.register(
      name: sampleName,
      address: sampleAddress,
      requirePhone: false,
    ),
  );
}
