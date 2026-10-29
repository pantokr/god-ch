import '../../../core/mvvm/view_model.dart';
import '../../../data/models/member.dart';
import '../../members/data/member_repository.dart';
import '../view/member_detail_dialog.dart';

enum MemberSort {
  newest('가입 최근 순'),
  oldest('가입 오래된 순'),
  name('이름 순'),
  role('역할 순');

  const MemberSort(this.label);

  final String label;
}

/// 인원 관리: 새로 등록된 인원의 승인, 등록된 인원 조회(검색 · 필터 · 정렬), 역할 지정.
/// 교역자는 일반 교인의 승인 상태만, 교회 운영자는 역할까지 바꿀 수 있다 (본인 계정은 제외).
class MemberAdminViewModel extends ViewModel {
  MemberAdminViewModel(this._members, this.me)
    : members = _members.members(me.churchId);

  /// 이 기간 안에 가입했으면 "새로 등록된 인원"으로 본다.
  static const newcomerDays = 7;

  final MemberRepository _members;
  final Member me;
  final Stream<List<Member>> members;

  // ---- 조회 조건 (등록된 인원 목록에만 적용된다) ----
  String _query = '';
  Role? _role;
  MemberStatus? _status;
  MemberSort _sort = MemberSort.newest;

  String get query => _query;
  Role? get roleFilter => _role;
  MemberStatus? get statusFilter => _status;
  MemberSort get sort => _sort;

  bool get hasFilter => _query.isNotEmpty || _role != null || _status != null;

  void setQuery(String v) => _update(() => _query = v.trim());
  void setRoleFilter(Role? v) => _update(() => _role = v);
  void setStatusFilter(MemberStatus? v) => _update(() => _status = v);
  void setSort(MemberSort v) => _update(() => _sort = v);

  void clearFilters() => _update(() {
    _query = '';
    _role = null;
    _status = null;
  });

  void _update(void Function() change) {
    change();
    notifyListeners();
  }

  // ---- 권한 ----
  bool canChangeStatus(Member m) =>
      m.id != me.id && (me.isAdmin || m.role == Role.member);

  bool canChangeRole(Member m) => m.id != me.id && me.isAdmin;

  /// 교인 삭제는 교회 운영자만, 본인 계정은 제외.
  bool canDelete(Member m) => m.id != me.id && me.isAdmin;

  /// 이름·전화번호는 교회 운영자만 고친다 (본인 정보는 '내 정보'에서).
  bool canEditProfile(Member m) => m.id != me.id && me.isAdmin;

  // ---- 목록 만들기 ----
  /// 승인을 기다리거나 최근에 가입한 인원.
  bool isNewcomer(Member m) {
    if (m.status == MemberStatus.pending) return true;
    final joined = m.createdAt;
    // 서버 시각이 아직 확정되지 않았으면 방금 가입한 것이다.
    if (joined == null) return true;
    return DateTime.now().difference(joined).inDays < newcomerDays;
  }

  /// 새로 등록된 인원: 승인 대기를 맨 위에, 그다음 최근 가입 순.
  List<Member> newcomers(List<Member> all) {
    final list = all.where(isNewcomer).toList();
    int rank(Member m) => m.status == MemberStatus.pending ? 0 : 1;
    list.sort((a, b) {
      final r = rank(a).compareTo(rank(b));
      return r != 0 ? r : _byJoined(b, a);
    });
    return list;
  }

  /// 검색어(이름·아이디·전화번호)에 맞는가. 검색어가 없으면 모두 맞다.
  bool matchesQuery(Member m) {
    final q = _query.toLowerCase();
    if (q.isEmpty) return true;
    return m.name.toLowerCase().contains(q) ||
        m.loginId.toLowerCase().contains(q) ||
        m.phone.replaceAll('-', '').contains(q.replaceAll('-', ''));
  }

  /// 이미 등록된 인원: 새로 등록된 인원을 뺀 나머지에서 조건에 맞는 사람을 정렬해서.
  List<Member> existing(List<Member> all) {
    final list = all.where((m) {
      if (isNewcomer(m)) return false;
      if (_role != null && m.role != _role) return false;
      if (_status != null && m.status != _status) return false;
      return matchesQuery(m);
    }).toList();
    list.sort(switch (_sort) {
      MemberSort.newest => (a, b) => _byJoined(b, a),
      MemberSort.oldest => (a, b) => _byJoined(a, b),
      MemberSort.name => (a, b) => a.name.compareTo(b.name),
      // 운영자 → 교역자 → 교인 순, 같으면 이름 순.
      MemberSort.role => (a, b) {
        final r = b.role.index.compareTo(a.role.index);
        return r != 0 ? r : a.name.compareTo(b.name);
      },
    });
    return list;
  }

  int _byJoined(Member a, Member b) =>
      (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now());

  // ---- 동작 ----
  Future<void> approve(Member m) =>
      run(() => _members.setStatus(me.churchId, m.id, MemberStatus.approved));

  Future<void> remove(Member m) =>
      run(() => _members.remove(me.churchId, me.churchName, m.id));

  /// 차단 목록에 올리고 교회에서 내보낸다.
  Future<void> block(Member m) =>
      run(() => _members.blockMember(me.churchId, me.churchName, m));

  Future<void> disable(Member m) =>
      run(() => _members.setStatus(me.churchId, m.id, MemberStatus.disabled));

  Future<void> setRole(Member m, Role role) =>
      run(() => _members.setRole(me.churchId, m.id, role));

  /// 상세 관리 저장: 바뀐 항목만 쓴다.
  Future<bool> saveDetail(Member m, MemberDetailResult r) {
    final change = r.changes.isEmpty ? null : r.changes.first;
    final profile = canEditProfile(m);
    return run(
      () => _members.saveMember(
        m,
        name: profile && r.name.trim() != m.name ? r.name : null,
        phone: profile && r.phone.trim() != m.phone ? r.phone : null,
        address: profile && r.address.trim() != m.address ? r.address : null,
        birthDate: profile && r.birthDate.trim() != m.birthDate
            ? r.birthDate
            : null,
        role: change?.role,
        status: change?.status,
      ),
    );
  }
}
