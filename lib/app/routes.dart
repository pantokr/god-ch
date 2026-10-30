/// 교회 안의 메뉴. 주소의 마지막 부분이 [path]다. 왼쪽 메뉴(서랍)에서 고른다.
enum ChurchSection {
  /// 기도제목: 공개 기도제목이 포스트잇 카드로 떠다닌다.
  prayer('prayer'),

  /// 모임(일정): 노션에 정리한 교회 모임 목록. 교회의 첫 화면이다.
  meetings('meetings'),

  /// 성경: 말씀묵상 글과 내 묵상.
  bible('bible'),

  /// 내 활동: 내가 쓴 기도제목과 묵상.
  mine('mine'),

  /// 중보기도 설정 (교회 운영자만): 중보기도 운영 방식.
  prayerSettings('prayer-settings'),

  /// 말씀묵상 설정 (교회 운영자만): 좋아요 · 댓글 · 조회수 · 글쓴이 운영 방식.
  devotionSettings('devotion-settings'),

  /// 직급 관리 (교회 운영자만): 직급 만들기 · 수정 · 삭제 · 권한 부여와 교인에게 직급 주기.
  positions('positions'),

  /// 인원 관리 (교역자·교회 운영자): 새로 등록된 인원 승인, 등록 인원 조회.
  members('members'),

  /// 교회 입장 관리 (교역자·교회 운영자): 입장 방식과 초대 코드.
  join('join'),

  /// 교회 정보 관리 (교회 운영자만): 교회 정보 수정과 폐쇄 요청.
  info('info'),

  /// 소속 관리 (교역자·교회 운영자): 소속 목록과 소속별 인원 (주소 `/affiliations/{소속}`).
  affiliations('affiliations');

  const ChurchSection(this.path);

  final String path;

  static ChurchSection? fromPath(String path) {
    for (final s in values) {
      if (s.path == path) return s;
    }
    return null;
  }
}

/// 앱 운영자 패널의 메뉴. 각 메뉴는 자기 주소를 가진다.
enum PlatformSection {
  dashboard(Routes.admin),
  churches(Routes.adminChurches),
  users(Routes.adminUsers);

  const PlatformSection(this.location);

  final String location;

  /// 현재 주소가 어느 메뉴에 속하는지 (교회 상세 주소는 교회 관리에 속한다).
  static PlatformSection fromPath(String path) {
    if (path.startsWith(Routes.adminChurches)) return churches;
    if (path.startsWith(Routes.adminUsers)) return users;
    return dashboard;
  }
}

/// 앱의 모든 화면 주소. 브라우저 주소창과 뒤로가기가 이 주소를 따라 움직인다.
class Routes {
  Routes._();

  // 로그인 전후의 안내 화면
  static const loading = '/loading';
  static const login = '/login';
  static const signUp = '/sign-up';
  static const profile = '/profile';

  // 회원
  static const churches = '/churches';

  /// 내 교회 목록을 일부러 열 때의 주소. 이 주소가 아닌 `/churches`는 소속 교회가 있으면
  /// 바로 그 교회의 메인으로 넘어간다.
  static const churchList = '/churches?list=1';

  /// 교회 탐색: 공개 탐색에 노출된 교회를 찾아 입장을 요청한다.
  static const explore = '/explore';

  /// 내 정보 페이지 (프로필 사진을 누르면 열린다).
  static const account = '/account';

  static String church(String churchId) => '/churches/$churchId';

  /// 교회 안의 메뉴.
  static String section(String churchId, ChurchSection s) =>
      '/churches/$churchId/${s.path}';

  /// 한 소속의 인원 관리 화면.
  static String affiliation(String churchId, String affId) =>
      '${section(churchId, ChurchSection.affiliations)}/$affId';

  /// 교회의 첫 화면 (일정).
  static String home(String churchId) =>
      section(churchId, ChurchSection.meetings);

  /// 말씀 상세 (교회 틀 밖의 전체 화면).
  static String devotion(String churchId, String id) =>
      '/churches/$churchId/devotion/$id';

  /// 모임 상세 (교회 틀 밖의 전체 화면).
  static String meeting(String churchId, String id) =>
      '/churches/$churchId/meeting/$id';

  static String prayer(String churchId, String prayerId) =>
      '/churches/$churchId/prayers/$prayerId';

  /// 새 기도제목 쓰기. [aff]가 있으면 그 소속이 기본 게시 범위다.
  static String newPrayer(String churchId, {String? aff}) {
    final base = '/churches/$churchId/prayers/new';
    return aff == null ? base : '$base?aff=$aff';
  }

  static String editPrayer(String churchId, String prayerId) =>
      '/churches/$churchId/prayers/$prayerId/edit';

  // 앱 운영자
  static const admin = '/admin';
  static const adminChurches = '/admin/churches';
  static const adminUsers = '/admin/users';

  /// 로그인 전 화면 주소들.
  static const publicPaths = {login, signUp};

  /// 로그인 상태가 정해지기 전이나 정보 입력 중에만 보이는 화면 주소들.
  static const gatePaths = {loading, login, signUp, profile};
}
