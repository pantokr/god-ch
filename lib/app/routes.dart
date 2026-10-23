import '../data/models/church_content.dart';

/// 교회 안의 메뉴. 주소의 마지막 부분이 [path]다.
enum ChurchSection {
  /// 교회 메인: 공지 캐러셀, 일정, 사진첩, 설교영상, 말씀묵상.
  home('home'),

  /// 중보기도: 기도제목 피드.
  feed('prayers'),

  /// 내 기도제목.
  mine('mine'),

  /// 메인 페이지 편집 (교역자·교회 운영자).
  content('content'),

  /// 교회 관리 (교역자·교회 운영자).
  manage('manage');

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
  static const verifyEmail = '/verify-email';
  static const profile = '/profile';

  // 회원
  static const churches = '/churches';

  /// 내 교회 목록을 일부러 열 때의 주소. 이 주소가 아닌 `/churches`는 소속 교회가 있으면
  /// 바로 그 교회의 메인으로 넘어간다.
  static const churchList = '/churches?list=1';

  static String church(String churchId) => '/churches/$churchId';

  /// 교회 안의 메뉴. [dept]가 있으면 그 부서 전용 공간으로 본다.
  static String section(String churchId, ChurchSection s, {String? dept}) {
    final base = '/churches/$churchId/${s.path}';
    return dept == null ? base : '$base?dept=$dept';
  }

  static String home(String churchId) => section(churchId, ChurchSection.home);

  /// 메인 콘텐츠 목록 (공지·일정·사진첩·설교영상·말씀묵상의 "더보기").
  static String contentList(String churchId, ContentKind kind) =>
      '/churches/$churchId/c/${kind.collection}';

  static String contentDetail(String churchId, ContentKind kind, String id) =>
      '${contentList(churchId, kind)}/$id';

  /// 메인 페이지 편집 화면. [kind]를 주면 그 종류의 탭이 열린다.
  static String contentEdit(String churchId, {ContentKind? kind}) {
    final base = section(churchId, ChurchSection.content);
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

  static String adminChurch(String churchId) => '/admin/churches/$churchId';

  /// 로그인 전 화면 주소들.
  static const publicPaths = {login, signUp};

  /// 로그인 상태가 정해지기 전이나 정보 입력 중에만 보이는 화면 주소들.
  static const gatePaths = {loading, login, signUp, verifyEmail, profile};
}
