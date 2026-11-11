import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:god_ch/app/app_scope.dart';
import 'package:god_ch/app/list_style_controller.dart';
import 'package:god_ch/app/preferences_controller.dart';
import 'package:god_ch/app/theme_mode_controller.dart';
import 'package:god_ch/core/theme.dart';
import 'package:god_ch/data/models/member.dart';
import 'package:god_ch/data/models/position.dart';
import 'package:god_ch/features/activity/data/activity_log_repository.dart';
import 'package:god_ch/features/admin/data/position_repository.dart';
import 'package:god_ch/features/admin/view/position_manage_page.dart';
import 'package:god_ch/features/auth/data/auth_repository.dart';
import 'package:god_ch/features/bible/data/bible_repository.dart';
import 'package:god_ch/features/church/data/affiliation_repository.dart';
import 'package:god_ch/features/church/data/church_closure_repository.dart';
import 'package:god_ch/features/church/data/church_repository.dart';
import 'package:god_ch/features/church/data/church_request_repository.dart';
import 'package:god_ch/features/auth/data/profile_repository.dart';
import 'package:god_ch/features/home/data/content_repository.dart';
import 'package:god_ch/features/home/data/reflection_repository.dart';
import 'package:god_ch/features/meetings/data/meeting_repository.dart';
import 'package:god_ch/features/members/data/member_repository.dart';
import 'package:god_ch/features/notifications/data/notification_repository.dart';
import 'package:god_ch/features/people/data/people_repository.dart';
import 'package:god_ch/features/platform/data/church_registry_repository.dart';
import 'package:god_ch/features/prayers/data/prayer_repository.dart';

class _Auth extends Fake implements AuthRepository {}

class _Profiles extends Fake implements ProfileRepository {}

class _Churches extends Fake implements ChurchRepository {}

class _Requests extends Fake implements ChurchRequestRepository {}

class _Registry extends Fake implements ChurchRegistryRepository {}

class _Closures extends Fake implements ChurchClosureRepository {}

class _Affs extends Fake implements AffiliationRepository {}

class _Contents extends Fake implements ContentRepository {}

class _Reflections extends Fake implements ReflectionRepository {}

class _Meetings extends Fake implements MeetingRepository {}

class _People extends Fake implements PeopleRepository {}

class _Prayers extends Fake implements PrayerRepository {}

class _Notifications extends Fake implements NotificationRepository {}

class _Bible extends Fake implements BibleRepository {}

class _Activity extends Fake implements ActivityLogRepository {}

class _Positions extends Fake implements PositionRepository {
  @override
  Stream<List<Position>> positions(String churchId) => Stream.value(const [
    Position(id: 'p1', name: '찬양팀', permissions: {'prayer.write'}),
  ]);
}

class _Members extends Fake implements MemberRepository {
  @override
  Stream<List<Member>> members(String churchId) => Stream.value(const []);
}

void main() {
  testWidgets('직급 권한 화면이 오류 없이 그려진다', (tester) async {
    const me = Member(
      id: 'u',
      churchId: 'c',
      churchName: '교회',
      name: '관리자',
      role: Role.admin,
      status: MemberStatus.approved,
    );
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AppScope(
        themeMode: ThemeModeController(null),
        listStyle: ListStyleController(null),
        preferences: PreferencesController(null),
        auth: _Auth(),
        profiles: _Profiles(),
        churches: _Churches(),
        churchRequests: _Requests(),
        churchRegistry: _Registry(),
        churchClosures: _Closures(),
        affiliations: _Affs(),
        contents: _Contents(),
        reflections: _Reflections(),
        meetings: _Meetings(),
        positions: _Positions(),
        members: _Members(),
        people: _People(),
        prayers: _Prayers(),
        notifications: _Notifications(),
        bible: _Bible(),
        activityLogs: _Activity(),
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          home: const Scaffold(body: PositionManagePage(me: me)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    // 직급 카드(찬양팀)와 기본 직급 카드가 보인다.
    expect(find.text('찬양팀'), findsOneWidget);
    expect(find.text('교역자'), findsOneWidget);
    expect(find.text('미배정'), findsNothing);
  });
}
