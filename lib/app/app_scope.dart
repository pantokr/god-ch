import 'package:flutter/widgets.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/profile_repository.dart';
import '../features/church/data/church_repository.dart';
import '../features/church/data/church_request_repository.dart';
import '../features/church/data/department_repository.dart';
import '../features/members/data/member_repository.dart';
import '../features/platform/data/church_registry_repository.dart';
import '../features/prayers/data/prayer_repository.dart';

/// 앱 전체에서 쓰는 저장소 모음. ViewModel을 만들 때 여기서 꺼내 주입한다.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.auth,
    required this.profiles,
    required this.churches,
    required this.churchRequests,
    required this.churchRegistry,
    required this.departments,
    required this.members,
    required this.prayers,
    required super.child,
  });

  final AuthRepository auth;
  final ProfileRepository profiles;
  final ChurchRepository churches;
  final ChurchRequestRepository churchRequests;
  final ChurchRegistryRepository churchRegistry;
  final DepartmentRepository departments;
  final MemberRepository members;
  final PrayerRepository prayers;

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
