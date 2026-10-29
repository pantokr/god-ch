import 'dart:typed_data';

import '../../../core/mvvm/view_model.dart';
import '../../../data/models/member.dart';
import '../../../data/models/user_profile.dart';
import '../../admin/view/member_detail_dialog.dart';
import '../../members/data/member_repository.dart';
import '../data/church_registry_repository.dart';

/// 앱 운영자 패널의 회원 관리: 가입한 회원 목록과 검색, 상세 수정.
class UsersViewModel extends ViewModel {
  UsersViewModel(this._registry, this._members)
    : users = _registry.users(),
      memberships = _registry.allMembers();

  final ChurchRegistryRepository _registry;
  final MemberRepository _members;

  final Stream<List<UserProfile>> users;

  /// 모든 교회의 교인 정보. 회원 한 명이 여러 교회에 속할 수 있다.
  final Stream<List<Member>> memberships;

  String _query = '';

  String get query => _query;

  void setQuery(String value) {
    _query = value.trim().toLowerCase();
    notifyListeners();
  }

  /// 이름·아이디·전화번호 중 하나라도 검색어를 포함하면 보여준다.
  bool matches(UserProfile u) {
    if (_query.isEmpty) return true;
    final digits = _query.replaceAll(RegExp(r'\D'), '');
    return u.name.toLowerCase().contains(_query) ||
        (u.loginId ?? '').contains(_query) ||
        (digits.isNotEmpty && u.phone.replaceAll('-', '').contains(digits));
  }

  /// 회원의 프로필 사진을 올린다. 성공하면 주소, 실패하면 null ([error]에 이유).
  Future<String?> uploadPhoto(
    String uid,
    String fileName,
    Uint8List bytes,
  ) async {
    String? url;
    await run(
      () async => url = await _registry.uploadUserPhoto(uid, fileName, bytes),
    );
    return url;
  }

  /// 상세 관리 저장: 바뀐 항목만 쓴다. 앱 운영자는 모든 교회에서 교회 운영자와 같은 권한이다.
  Future<bool> saveDetail(UserProfile u, MemberDetailResult r) => run(() async {
    if (r.name.trim() != u.name ||
        r.phone.trim() != u.phone ||
        r.address.trim() != u.address ||
        r.birthDate.trim() != u.birthDate ||
        r.photoUrl.trim() != u.photoUrl) {
      await _registry.updateUser(
        u.uid,
        name: r.name,
        phone: r.phone,
        address: r.address,
        birthDate: r.birthDate,
        photoUrl: r.photoUrl,
      );
    }
    for (final c in r.changes) {
      await _members.saveMember(c.member, role: c.role, status: c.status);
    }
  });
}
