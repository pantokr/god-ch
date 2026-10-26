import 'dart:typed_data';

import '../../../core/mvvm/view_model.dart';
import '../../../data/models/user_profile.dart';
import '../data/profile_repository.dart';

/// 내 정보 수정: 현재 프로필을 읽어 오고 이름·전화번호를 저장한다.
class ProfileEditViewModel extends ViewModel {
  ProfileEditViewModel(this._profiles) {
    _load();
  }

  final ProfileRepository _profiles;

  bool _loaded = false;
  UserProfile? _profile;

  bool get loaded => _loaded;

  /// 회원 프로필이 없는 계정(앱 운영자)은 null.
  UserProfile? get profile => _profile;

  Future<void> _load() async {
    await run(() async => _profile = await _profiles.current());
    _loaded = true;
    notifyListeners();
  }

  Future<bool> save(
    String name,
    String phone, {
    String? address,
    String? birthDate,
    String? photoUrl,
  }) => run(
    () => _profiles.update(
      name: name,
      phone: phone,
      address: address,
      birthDate: birthDate,
      photoUrl: photoUrl,
    ),
  );

  /// 프로필 사진을 올린다. 성공하면 주소, 실패하면 null ([error]에 이유).
  Future<String?> uploadPhoto(String fileName, Uint8List bytes) async {
    String? url;
    await run(() async => url = await _profiles.uploadPhoto(fileName, bytes));
    return url;
  }
}
