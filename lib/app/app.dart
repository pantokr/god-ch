import '../features/activity/data/activity_log_repository.dart';
import '../features/bible/data/bible_repository.dart';
import '../features/people/data/people_repository.dart';
import '../features/notifications/data/notification_repository.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../core/layout/responsive.dart';

import '../core/theme.dart';
import '../features/admin/data/position_repository.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/profile_repository.dart';
import '../features/church/data/affiliation_repository.dart';
import '../features/church/data/church_closure_repository.dart';
import '../features/church/data/church_repository.dart';
import '../features/church/data/church_request_repository.dart';
import '../features/home/data/content_repository.dart';
import '../features/meetings/data/meeting_repository.dart';
import '../features/home/data/reflection_repository.dart';
import '../features/members/data/member_repository.dart';
import '../features/platform/data/church_registry_repository.dart';
import '../features/prayers/data/prayer_repository.dart';
import '../core/widgets/offline_banner.dart';
import 'app_scope.dart';
import 'connectivity_controller.dart';
import 'router.dart';
import 'session.dart';
import 'list_style_controller.dart';
import 'preferences_controller.dart';
import 'theme_mode_controller.dart';

class App extends StatefulWidget {
  const App({
    super.key,
    required this.themeMode,
    required this.listStyle,
    required this.preferences,
  });

  /// 개인 설정(글씨 크기, 신규 표시, 화면별 기본 보기 · 정렬).
  final PreferencesController preferences;

  /// 저장된 화면 모드. 앱이 시작될 때 한 번 불러와 넘겨 준다.
  final ThemeModeController themeMode;

  /// 목록 화면 모양(알록달록 · 심플).
  final ListStyleController listStyle;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  // 저장소는 앱이 살아있는 동안 한 번만 만든다.
  late final _db = FirebaseFirestore.instance;
  late final AuthRepository _auth = AuthRepository(FirebaseAuth.instance, _db);
  // 접속 · 활동 기록: 아래 저장소들이 일이 끝난 뒤 한 줄씩 남긴다.
  late final ActivityLogRepository _activity = ActivityLogRepository(
    _db,
    _auth,
  );
  late final ProfileRepository _profiles = ProfileRepository(
    _db,
    _auth,
    _contents,
    activity: _activity,
  );
  late final ChurchRepository _churches = ChurchRepository(
    _db,
    _auth,
    _profiles,
    activity: _activity,
  );
  late final ChurchRequestRepository _churchRequests = ChurchRequestRepository(
    _db,
    _auth,
    _profiles,
  );
  late final ChurchClosureRepository _churchClosures = ChurchClosureRepository(
    _db,
    _auth,
    _profiles,
  );
  late final ChurchRegistryRepository _churchRegistry =
      ChurchRegistryRepository(_db, _auth, _contents);
  late final AffiliationRepository _affiliations = AffiliationRepository(
    _db,
    _auth,
    activity: _activity,
  );
  late final ContentRepository _contents = ContentRepository(
    _db,
    FirebaseStorage.instance,
    _auth,
    activity: _activity,
  );
  late final ReflectionRepository _reflections = ReflectionRepository(
    _db,
    _auth,
    activity: _activity,
  );
  late final MeetingRepository _meetings = MeetingRepository(
    _db,
    _auth,
    _contents,
    activity: _activity,
  );
  late final PositionRepository _positions = PositionRepository(
    _db,
    _auth,
    activity: _activity,
  );
  late final MemberRepository _members = MemberRepository(
    _db,
    _auth,
    activity: _activity,
  );
  late final PeopleRepository _people = PeopleRepository(_db);
  late final PrayerRepository _prayers = PrayerRepository(
    _db,
    _auth,
    activity: _activity,
  );
  late final BibleRepository _bible = BibleRepository(FirebaseStorage.instance);
  late final NotificationRepository _notifications = NotificationRepository(
    _db,
    _auth,
  );

  // 테마는 한 번만 만들어 둔다 (글꼴 설정까지 포함해 만드는 비용이 있다).
  final _light = buildTheme(Brightness.light);
  final _dark = buildTheme(Brightness.dark);

  // 로그인 상태와 주소 체계. 라우터는 한 번만 만들어 앱이 사는 동안 유지한다.
  late final SessionNotifier _session = SessionNotifier(
    _auth,
    _profiles,
    _churchRequests,
    activity: _activity,
  );
  late final _router = buildRouter(_session);

  // 인터넷 연결 여부: 끊기면 모든 페이지 맨 위에 "인터넷 연결 없음" 띠가 붙는다.
  late final ConnectivityController _connectivity = ConnectivityController();

  @override
  void initState() {
    super.initState();
    // 로그인 · 로그아웃 기록을 인증 저장소가 직접 남긴다 (두 저장소가 서로를 쓰므로 만든 뒤에 잇는다).
    _auth.activity = _activity;
  }

  @override
  void dispose() {
    _router.dispose();
    _connectivity.dispose();
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      themeMode: widget.themeMode,
      listStyle: widget.listStyle,
      preferences: widget.preferences,
      auth: _auth,
      profiles: _profiles,
      churches: _churches,
      churchRequests: _churchRequests,
      churchRegistry: _churchRegistry,
      churchClosures: _churchClosures,
      affiliations: _affiliations,
      contents: _contents,
      reflections: _reflections,
      meetings: _meetings,
      positions: _positions,
      members: _members,
      people: _people,
      prayers: _prayers,
      notifications: _notifications,
      bible: _bible,
      activityLogs: _activity,
      // 화면 모드가 바뀌면 앱 전체가 새 테마로 다시 그려진다.
      child: ListenableBuilder(
        listenable: widget.themeMode,
        builder: (context, _) => MaterialApp.router(
          title: '같이',
          debugShowCheckedModeBanner: false,
          theme: _light,
          darkTheme: _dark,
          themeMode: widget.themeMode.mode,
          routerConfig: _router,
          builder: (context, child) => ListenableBuilder(
            listenable: widget.preferences,
            builder: (context, _) => MediaQuery(
              // 글씨를 키운다: 폰은 조금, 와이드는 더. 사용자가 정한 글씨 크기에 곱하고 너무 커지지 않게 상한을 둔다.
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(
                  (MediaQuery.textScalerOf(context).scale(1) *
                          (MediaQuery.sizeOf(context).width < kNarrow
                              ? 1.08
                              : 1.18) *
                          widget.preferences.textSize.factor)
                      .clamp(0.9, 1.5),
                ),
              ),
              // 모든 페이지가 아래쪽 시스템 내비게이션 바(제스처 바·버튼)에 가리지 않도록 그만큼 비워 둔다.
              child: ColoredBox(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: SafeArea(
                  top: false,
                  left: false,
                  right: false,
                  child: ListenableBuilder(
                    listenable: _connectivity,
                    builder: (context, _) => OfflineBanner(
                      visible: !_connectivity.online,
                      child: child!,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
