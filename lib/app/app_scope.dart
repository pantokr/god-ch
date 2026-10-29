import 'package:flutter/widgets.dart';

import '../features/admin/data/sample_data_repository.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/bible/data/bible_repository.dart';
import '../features/auth/data/profile_repository.dart';
import '../features/church/data/church_closure_repository.dart';
import '../features/church/data/church_repository.dart';
import '../features/church/data/church_request_repository.dart';
import '../features/home/data/content_repository.dart';
import '../features/meetings/data/meeting_repository.dart';
import '../features/home/data/reflection_repository.dart';
import '../features/members/data/member_repository.dart';
import '../features/notifications/data/notification_repository.dart';
import '../features/platform/data/church_registry_repository.dart';
import '../features/prayers/data/prayer_repository.dart';
import 'list_style_controller.dart';
import 'theme_mode_controller.dart';

/// 앱 전체에서 쓰는 저장소 모음. ViewModel을 만들 때 여기서 꺼내 주입한다.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.themeMode,
    required this.listStyle,
    required this.auth,
    required this.profiles,
    required this.churches,
    required this.churchRequests,
    required this.churchRegistry,
    required this.churchClosures,
    required this.contents,
    required this.reflections,
    required this.meetings,
    required this.sampleData,
    required this.members,
    required this.prayers,
    required this.notifications,
    required this.bible,
    required super.child,
  });

  /// 화면 모드(시스템/라이트/다크).
  final ThemeModeController themeMode;

  /// 목록 화면 모양(알록달록 · 심플).
  final ListStyleController listStyle;
  final AuthRepository auth;
  final ProfileRepository profiles;
  final ChurchRepository churches;
  final ChurchRequestRepository churchRequests;
  final ChurchRegistryRepository churchRegistry;
  final ChurchClosureRepository churchClosures;
  final ContentRepository contents;
  final ReflectionRepository reflections;
  final MeetingRepository meetings;
  final SampleDataRepository sampleData;
  final MemberRepository members;
  final PrayerRepository prayers;
  final NotificationRepository notifications;
  final BibleRepository bible;

  /// 위젯 상태를 만들 때(initState 등)도 쓸 수 있도록 의존성 등록 없이 읽는다.
  static AppScope read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope가 위젯 트리에 없습니다.');
    return scope!;
  }

  // 저장소는 앱 실행 중 바뀌지 않는다.
  @override
  bool updateShouldNotify(AppScope oldWidget) => false;
}
