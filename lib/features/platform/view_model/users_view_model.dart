import '../../../core/mvvm/view_model.dart';
import '../../../data/models/user_profile.dart';
import '../data/church_registry_repository.dart';

/// 앱 운영자 패널의 회원 관리: 가입한 회원 목록과 검색.
class UsersViewModel extends ViewModel {
  UsersViewModel(ChurchRegistryRepository registry) : users = registry.users();

  final Stream<List<UserProfile>> users;

  String _query = '';

  String get query => _query;

  void setQuery(String value) {
    _query = value.trim().toLowerCase();
    notifyListeners();
  }

  /// 이름·아이디·이메일·전화번호 중 하나라도 검색어를 포함하면 보여준다.
  bool matches(UserProfile u) {
    if (_query.isEmpty) return true;
    final digits = _query.replaceAll(RegExp(r'\D'), '');
    return u.name.toLowerCase().contains(_query) ||
        (u.loginId ?? '').contains(_query) ||
        u.email.toLowerCase().contains(_query) ||
        (digits.isNotEmpty && u.phone.replaceAll('-', '').contains(digits));
  }
}
