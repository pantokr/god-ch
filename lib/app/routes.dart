import '../data/models/church_content.dart';

/// 교회 안의 메뉴. 주소의 마지막 부분이 [path]다.
enum ChurchSection {
  /// 교회 메인: 공지 캐러셀, 일정, 사진첩, 설교영상, 말씀묵상.
  home('home'),

  /// 교역자가 구성한 페이지 (주소 `/p/{페이지}`). 메인 · 말씀 묵상 등.
  page('p'),

  /// 하단 탭 왼쪽 버튼: 그 자리에 놓인 페이지 하나.
  left('left'),

  /// 하단 탭 오른쪽 버튼: 그 자리에 놓인 페이지 하나.
  right('right'),

  /// 내 활동: 기도 요청 · 말씀 묵상 페이지에 따라 자동으로 모이는 내 글.
  mine('mine'),

  /// 갤러리: 사진첩의 사진만 모아 보는 별도의 탭.
  gallery('gallery'),

  /// 페이지 편집 (교역자·교회 운영자): 메뉴의 페이지와 페이지 구성.
  content('content'),

  /// 콘텐츠 관리 (교회 운영자만): 공지·일정 같은 글을 종류별로 올리고 고친다.
  contents('contents'),

  /// 인원 관리 (교역자·교회 운영자): 새로 등록된 인원 승인, 등록 인원 조회.
  members('members'),

  /// 교회 입장 관리 (교역자·교회 운영자): 입장 방식과 초대 코드.
  join('join'),

  /// 교회 정보 관리 (교회 운영자만): 교회 정보 수정과 폐쇄 요청.
  info('info'),

  /// 부서 관리 (교역자·교회 운영자): 부서 목록과 부서별 인원 (주소 `/departments/{부서}`).
  departments('departments');

  const ChurchSection(this.path);

  final String path;

  static ChurchSection? fromPath(String path) {
    // 예전 주소(기도 · 말씀 탭)는 왼쪽 · 오른쪽 버튼으로 이어진다.
    if (path == 'intercession') return left;
    if (path == 'word') return right;
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

  /// 교회 안의 메뉴. [dept]가 있으면 그 부서 전용 공간으로 본다.
  static String section(String churchId, ChurchSection s, {String? dept}) {
    final base = '/churches/$churchId/${s.path}';
    return dept == null ? base : '$base?dept=$dept';
  }

  static String home(String churchId) => section(churchId, ChurchSection.home);

  /// 교역자가 구성한 페이지. [dept]가 있으면 그 부서 전용 공간으로 본다.
  static String page(String churchId, String pageId, {String? dept}) {
    final base = '/churches/$churchId/p/$pageId';
    return dept == null ? base : '$base?dept=$dept';
  }

  /// 메인 콘텐츠 목록 (공지·일정·사진첩·설교영상·말씀묵상의 "더보기").
  static String contentList(String churchId, ContentKind kind) =>
      '/churches/$churchId/c/${kind.collection}';

  static String contentDetail(String churchId, ContentKind kind, String id) =>
      '${contentList(churchId, kind)}/$id';

  /// 한 페이지의 구성(구조·디자인)을 고치는 화면.
  static String pageEdit(String churchId, String pageId) =>
      '${section(churchId, ChurchSection.content)}/p/$pageId';

  /// 한 부서의 인원 관리 화면.
  static String department(String churchId, String deptId) =>
      '${section(churchId, ChurchSection.departments)}/$deptId';

  /// 페이지 편집 화면 (페이지 목록).
  static String pageList(String churchId) =>
      section(churchId, ChurchSection.content);

  /// 콘텐츠 관리 화면. [kind]를 주면 그 종류(공지·일정 …)의 글 관리 화면이 열린다.
  static String contentEdit(String churchId, {ContentKind? kind}) {
    final base = section(churchId, ChurchSection.contents);
    return kind == null ? base : '$base?kind=${kind.collection}';
  }

  static String prayer(String churchId, String prayerId) =>
      '/churches/$churchId/prayers/$prayerId';

  static String newPrayer(String churchId, {String? dept}) {
    final base = '/churches/$churchId/prayers/new';
    return dept == null ? base : '$base?dept=$dept';
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
