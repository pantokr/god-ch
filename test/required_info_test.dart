import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:god_ch/core/screen_style.dart';
import 'package:god_ch/core/theme.dart';
import 'package:god_ch/core/widgets/create_fab.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:god_ch/app/app_scope.dart';
import 'package:god_ch/app/list_style_controller.dart';
import 'package:god_ch/app/preferences_controller.dart';
import 'package:god_ch/app/theme_mode_controller.dart';
import 'package:god_ch/features/activity/data/activity_log_repository.dart';
import 'package:god_ch/features/admin/data/position_repository.dart';
import 'package:god_ch/features/auth/data/auth_repository.dart';
import 'package:god_ch/features/auth/data/profile_repository.dart';
import 'package:god_ch/features/bible/data/bible_repository.dart';
import 'package:god_ch/features/church/data/church_closure_repository.dart';
import 'package:god_ch/features/church/data/church_repository.dart';
import 'package:god_ch/features/church/data/church_request_repository.dart';
import 'package:god_ch/features/home/data/content_repository.dart';
import 'package:god_ch/features/home/data/reflection_repository.dart';
import 'package:god_ch/features/inquiry/data/inquiry_repository.dart';
import 'package:god_ch/features/meetings/data/meeting_repository.dart';
import 'package:god_ch/features/notifications/data/notification_repository.dart';
import 'package:god_ch/features/people/data/people_repository.dart';
import 'package:god_ch/features/platform/data/church_registry_repository.dart';
import 'package:god_ch/features/prayers/data/prayer_repository.dart';
import 'package:god_ch/data/models/affiliation.dart';
import 'package:god_ch/data/models/user_profile.dart';
import 'package:god_ch/features/auth/view/my_affiliations_card.dart';
import 'package:god_ch/features/auth/view/profile_edit_dialog.dart';
import 'package:god_ch/data/models/member.dart';
import 'package:god_ch/data/models/profile_field.dart';
import 'package:god_ch/features/admin/view_model/member_admin_view_model.dart';
import 'package:god_ch/features/church/data/affiliation_repository.dart';
import 'package:god_ch/features/church/view/required_info_gate.dart';
import 'package:god_ch/features/members/data/member_repository.dart';

Member _me({
  String address = '',
  String birthDate = '',
  Role role = Role.member,
  MemberStatus status = MemberStatus.approved,
  String id = 'me',
}) => Member(
  id: id,
  churchId: 'c',
  churchName: '은혜교회',
  name: '김성도',
  role: role,
  status: status,
  address: address,
  birthDate: birthDate,
);

class _Members extends Fake implements MemberRepository {
  @override
  Stream<List<Member>> members(String churchId) => const Stream.empty();

  @override
  Future<void> syncAdminAffiliations(String churchId) async {}
}

class _Affiliations extends Fake implements AffiliationRepository {
  @override
  Stream<List<Affiliation>> affiliations(String churchId) =>
      const Stream.empty();
}

class _Auth extends Fake implements AuthRepository {}

class _Profiles extends Fake implements ProfileRepository {}

class _ProfilesLoaded extends Fake implements ProfileRepository {
  @override
  Future<UserProfile?> current() async => const UserProfile(
    uid: 'me',
    name: '김성도',
    phone: '010-0000-0030',
    consentThirdParty: true,
  );
}

class _Churches extends Fake implements ChurchRepository {
  _Churches([this.mine = const []]);

  final List<Member> mine;

  @override
  Stream<List<Member>> myMemberships() => Stream.value(mine);
}

class _Requests extends Fake implements ChurchRequestRepository {}

class _Registry extends Fake implements ChurchRegistryRepository {}

class _Closures extends Fake implements ChurchClosureRepository {}

class _Contents extends Fake implements ContentRepository {}

class _Reflections extends Fake implements ReflectionRepository {}

class _Meetings extends Fake implements MeetingRepository {}

class _People extends Fake implements PeopleRepository {}

class _Prayers extends Fake implements PrayerRepository {}

class _Bible extends Fake implements BibleRepository {}

class _Inquiries extends Fake implements InquiryRepository {}

class _Activity extends Fake implements ActivityLogRepository {}

class _Positions extends Fake implements PositionRepository {}

class _Notifications extends Fake implements NotificationRepository {}

Widget _app(
  Widget home, {
  List<Member> memberships = const [],
  ProfileRepository? profiles,
  PreferencesController? preferences,
}) => AppScope(
  themeMode: ThemeModeController(null),
  listStyle: ListStyleController(null),
  preferences: preferences ?? PreferencesController(null),
  auth: _Auth(),
  profiles: profiles ?? _Profiles(),
  churches: _Churches(memberships),
  churchRequests: _Requests(),
  churchRegistry: _Registry(),
  churchClosures: _Closures(),
  affiliations: _Affiliations(),
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
  inquiries: _Inquiries(),
  child: MaterialApp(theme: buildTheme(Brightness.light), home: home),
);

void main() {
  group('필수 정보가 비어 있는지', () {
    test('교회가 요청하지 않은 항목은 비어도 괜찮다', () {
      expect(RequiredInfoGate.missing(_me(), {}), isEmpty);
    });

    test('요청한 항목이 비어 있으면 그 항목만 모자란다', () {
      final missing = RequiredInfoGate.missing(_me(address: '서울시'), {
        ProfileField.address,
        ProfileField.birthDate,
      });
      expect(missing, {ProfileField.birthDate});
    });

    test('모두 채워져 있으면 모자란 것이 없다', () {
      final m = _me(address: '서울시', birthDate: '1990-01-01');
      expect(
        RequiredInfoGate.missing(m, {
          ProfileField.address,
          ProfileField.birthDate,
        }),
        isEmpty,
      );
    });
  });

  testWidgets('필수 정보가 비어 있으면 채우기 전에는 교회 화면이 가려진다', (tester) async {
    final required = StreamController<Set<ProfileField>>();
    addTearDown(required.close);
    await tester.pumpWidget(
      _app(
        RequiredInfoGate(
          me: _me(),
          requirements: required.stream,
          child: const Scaffold(body: Text('교회 화면')),
        ),
      ),
    );
    // 요청이 확인되기 전에는 막지 않는다.
    expect(find.text('교회 화면'), findsOneWidget);

    required.add({ProfileField.birthDate});
    await tester.pump();
    expect(find.text('교회 화면'), findsNothing);
    expect(find.text('은혜교회 필수 정보'), findsOneWidget);
    expect(find.textContaining('생년월일', findRichText: true), findsOneWidget);
    expect(find.textContaining('주소', findRichText: true), findsNothing);

    // 교회가 요청을 거두면 다시 들어갈 수 있다.
    required.add({});
    await tester.pump();
    expect(find.text('교회 화면'), findsOneWidget);
  });

  testWidgets('앱 개발자 화면은 막지 않는다', (tester) async {
    final operator = Member(
      id: 'op',
      churchId: 'c',
      churchName: '은혜교회',
      name: '운영자',
      role: Role.admin,
      status: MemberStatus.approved,
      isOperatorView: true,
    );
    await tester.pumpWidget(
      _app(
        RequiredInfoGate(
          me: operator,
          requirements: Stream.value({ProfileField.address}),
          child: const Scaffold(body: Text('교회 화면')),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('교회 화면'), findsOneWidget);
  });

  testWidgets('내가 속한 교회 카드에 교회별 제출 정보(주소 · 생년월일)가 보인다', (tester) async {
    await tester.pumpWidget(
      _app(
        const Scaffold(
          body: SingleChildScrollView(child: MyAffiliationsCard()),
        ),
        memberships: [
          _me(address: '서울시 중구', birthDate: '1990-01-01'),
          Member(
            id: 'me',
            churchId: 'c2',
            churchName: '평화교회',
            name: '김성도',
            role: Role.member,
            status: MemberStatus.approved,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('은혜교회'), findsOneWidget);
    expect(find.text('서울시 중구'), findsOneWidget);
    expect(find.text('1990-01-01'), findsOneWidget);
    // 제출한 것이 없는 교회에는 제출 정보 줄이 없다.
    expect(find.text('평화교회'), findsOneWidget);
    expect(find.text('주소'), findsOneWidget);
    expect(find.text('생년월일'), findsOneWidget);
  });

  testWidgets('내 정보 페이지를 열어 프로필을 불러와도 오류가 없고 전화번호가 채워진다', (tester) async {
    await tester.pumpWidget(
      _app(
        const Scaffold(
          body: SingleChildScrollView(
            child: ProfileEditDialog(name: '김성도', embedded: true),
          ),
        ),
        profiles: _ProfilesLoaded(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('010-0000-0030'), findsOneWidget);
  });

  testWidgets('새 글 플로팅 버튼은 화면의 글씨 크기 설정과 상관없이 크기가 같다', (tester) async {
    // 중보기도 · 말씀묵상 글씨를 크게 골라도 화면 밖의 버튼과 같은 크기다.
    SharedPreferences.setMockInitialValues({'size_bible': 'large'});
    final prefs = await PreferencesController.load();
    Widget fab() => CreateFab(label: '새 글', onTap: () {});
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: Column(
            children: [
              KeyedSubtree(key: const Key('out'), child: fab()),
              ScreenStyle(
                screen: 'prayer',
                child: KeyedSubtree(key: const Key('in'), child: fab()),
              ),
              ScreenStyle(
                screen: 'bible',
                child: KeyedSubtree(key: const Key('in2'), child: fab()),
              ),
              // 일반 글자는 화면 설정을 따라 커진다.
              const Text('가나다', key: Key('t0')),
              const ScreenStyle(
                screen: 'prayer',
                child: Text('가나다', key: Key('t1')),
              ),
            ],
          ),
        ),
        preferences: prefs,
      ),
    );
    final out = tester.getSize(find.byKey(const Key('out')));
    expect(tester.getSize(find.byKey(const Key('in'))), out);
    expect(tester.getSize(find.byKey(const Key('in2'))), out);
    expect(
      tester.getSize(find.byKey(const Key('t1'))).width,
      greaterThan(tester.getSize(find.byKey(const Key('t0'))).width),
    );
  });

  group('입장 요청 거절', () {
    MemberAdminViewModel vm(Member me) =>
        MemberAdminViewModel(_Members(), _Affiliations(), me);

    test('인원 관리 권한이 있는 교역자는 일반 교인의 요청을 거절한다', () {
      final staff = vm(_me(role: Role.staff, id: 'staff'));
      final pending = _me(status: MemberStatus.pending, id: 'new');
      expect(staff.canReject(pending), isTrue);
      staff.dispose();
    });

    test('교역자는 교역자 요청을 거절하지 못하고, 승인된 교인은 추방(교회 운영자)이다', () {
      final staff = vm(_me(role: Role.staff, id: 'staff'));
      expect(
        staff.canReject(
          _me(role: Role.staff, status: MemberStatus.pending, id: 'x'),
        ),
        isFalse,
      );
      expect(staff.canReject(_me(id: 'active')), isFalse);
      staff.dispose();
    });

    test('교인은 거절할 수 없고, 교회 운영자는 교역자 요청도 거절한다', () {
      final member = vm(_me(id: 'm'));
      final admin = vm(_me(role: Role.admin, id: 'a'));
      final pendingStaff = _me(
        role: Role.staff,
        status: MemberStatus.pending,
        id: 'x',
      );
      expect(member.canReject(_me(status: MemberStatus.pending)), isFalse);
      expect(admin.canReject(pendingStaff), isTrue);
      member.dispose();
      admin.dispose();
    });
  });

  group('firestore.rules', () {
    final rules = File('firestore.rules').readAsStringSync();

    test('주소 · 생년월일은 비어 있을 때 한 번만 채울 수 있고 고치거나 비울 수 없다', () {
      expect(rules, isNot(contains('blankedRequired')));
      expect(rules, contains("changed().hasOnly(['address', 'birthDate'])"));
      expect(rules, contains("resource.data.get('address', '') == ''"));
      expect(rules, contains("resource.data.get('birthDate', '') == ''"));
    });

    test('본인 · 앱 운영자의 교인 정보 수정에는 주소 · 생년월일이 없다', () {
      expect(
        RegExp(
          r"changed\(\)\.hasOnly\(\['name', 'phone', 'address', 'birthDate'",
        ).hasMatch(rules),
        isFalse,
      );
    });

    test('입장 요청 거절 알림은 인원 관리 권한으로도 보낼 수 있다', () {
      expect(rules, contains('function removalNoticeOk('));
      expect(rules, contains("can(churchId, 'member.manage'))"));
    });
  });
}
