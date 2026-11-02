import '../../../core/mvvm/view_model.dart';
import '../../../data/models/affiliation.dart';
import '../../../data/models/member.dart';
import '../../../data/models/permission.dart';
import '../../church/data/affiliation_repository.dart';
import '../../members/data/member_repository.dart';
import '../view/member_detail_dialog.dart';

enum MemberSort {
  name('이름순'),
  loginId('ID순'),
  joined('등록순'),
  position('직급순');

  const MemberSort(this.label);

  final String label;
}

/// 인원 관리: 새로 등록된 인원의 승인, 등록된 인원 조회(검색 · 필터 · 정렬), 역할 지정.
/// 교역자는 일반 교인의 승인 상태만, 교회 운영자는 역할까지 바꿀 수 있다 (본인 계정은 제외).
class MemberAdminViewModel extends ViewModel {
  MemberAdminViewModel(
    this._members,
    AffiliationRepository affiliations,
    this.me,
  ) : members = _members.members(me.churchId),
      affiliations = affiliations.affiliations(me.churchId) {
    // 교회 운영자는 모든 소속에 자동으로 속한다 (예전 데이터도 여기서 맞춘다).
    if (me.isStaff) {
      _members.syncAdminAffiliations(me.churchId).catchError((_) {});
    }
  }

  /// 이 기간 안에 가입했으면 "새로 등록된 인원"으로 본다.
  static const newcomerDays = 7;

  final MemberRepository _members;
  final Member me;
  final Stream<List<Member>> members;
  final Stream<List<Affiliation>> affiliations;

  // ---- 조회 조건 (등록된 인원 목록에만 적용된다) ----
  String _query = '';
  MemberSort _sort = MemberSort.name;

  String get query => _query;
  MemberSort get sort => _sort;

  void setQuery(String v) => _update(() => _query = v.trim());
  void setSort(MemberSort v) => _update(() => _sort = v);

  void _update(void Function() change) {
    change();
    notifyListeners();
  }

  // ---- 권한 ----
  /// 이미 승인된 사람은 상태를 바꾸지 못한다 (역할 · 소속만 바꾼다).
  bool canChangeStatus(Member m) =>
      m.id != me.id &&
      m.status != MemberStatus.approved &&
      (me.isAdmin || m.role == Role.member);

  bool canChangeRole(Member m) => m.id != me.id && me.isAdmin;

  /// 교인 삭제는 교회 운영자만, 본인 계정은 제외.
  bool canDelete(Member m) => m.id != me.id && me.isAdmin;

  /// 교회 회원 관리에서는 본인이 정한 개인정보(이름 · 전화번호 · 주소 · 생년월일)를 고치지 못하고 볼 수만 있다
  /// (본인 정보는 '내 정보'에서 본인이 고친다). 역할 · 소속 · 승인 여부만 관리한다.
  bool canEditProfile(Member m) => false;

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
      return matchesQuery(m);
    }).toList();
    list.sort(sorter);
    return list;
  }

  /// 고른 정렬 기준의 비교 함수.
  /// - 이름순: 가나다순.
  /// - ID순: 아이디(없으면 이메일) 순.
  /// - 등록순: 먼저 등록한 사람이 위.
  /// - 직급순: 교회 관리자 → 교역자 → 교인, 같은 역할 안에서는 직급이 있는 사람이 먼저, 같으면 이름순.
  int Function(Member, Member) get sorter => comparatorFor(_sort);

  /// [sort] 기준의 비교 함수 (소속 인원 목록도 같은 정렬을 쓴다).
  static int Function(Member, Member) comparatorFor(MemberSort sort) =>
      switch (sort) {
        MemberSort.name => (a, b) => a.name.compareTo(b.name),
        MemberSort.loginId => (a, b) {
          String key(Member m) =>
              (m.loginId.isNotEmpty ? m.loginId : m.email).toLowerCase();
          final r = key(a).compareTo(key(b));
          return r != 0 ? r : a.name.compareTo(b.name);
        },
        MemberSort.joined => (a, b) => _byJoined(a, b),
        MemberSort.position => (a, b) {
          final role = b.role.index.compareTo(a.role.index);
          if (role != 0) return role;
          final pos = (a.positionId == null ? 1 : 0).compareTo(
            b.positionId == null ? 1 : 0,
          );
          if (pos != 0) return pos;
          final byId = (a.positionId ?? '').compareTo(b.positionId ?? '');
          return byId != 0 ? byId : a.name.compareTo(b.name);
        },
      };

  static int _byJoined(Member a, Member b) =>
      (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now());

  // ---- 동작 ----
  Future<void> approve(Member m) =>
      run(() => _members.setStatus(me.churchId, m.id, MemberStatus.approved));

  /// 입장 요청을 승인하면서 역할과 소속을 함께 정한다. 바뀌지 않은 항목은 쓰지 않는다.
  Future<void> approveWith(
    Member m, {
    required Role role,
    required List<String> affiliationIds,
  }) => run(
    () => _members.saveMember(
      m,
      role: canChangeRole(m) && role != m.role ? role : null,
      affiliationIds: canAssignAffiliation(m) ? affiliationIds : null,
      status: MemberStatus.approved,
    ),
  );

  /// 소속 인원 배치 권한이 있는가 (본인 문서는 제외).
  bool canAssignAffiliation(Member m) =>
      m.id != me.id && me.can(Permission.affiliationAssign);

  Future<void> remove(Member m) =>
      run(() => _members.remove(me.churchId, me.churchName, m.id));

  /// 차단 목록에 올리고 교회에서 내보낸다.
  Future<void> block(Member m) =>
      run(() => _members.blockMember(me.churchId, me.churchName, m));

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
        affiliationIds: change?.affiliationIds,
        role: change?.role,
        status: change?.status,
      ),
    );
  }
}
