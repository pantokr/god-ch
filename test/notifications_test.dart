import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:god_ch/app/app_scope.dart';
import 'package:god_ch/app/list_style_controller.dart';
import 'package:god_ch/app/preferences_controller.dart';
import 'package:god_ch/app/theme_mode_controller.dart';
import 'package:god_ch/core/theme.dart';
import 'package:god_ch/data/models/app_notification.dart';
import 'package:god_ch/data/models/meeting.dart';
import 'package:god_ch/features/activity/data/activity_log_repository.dart';
import 'package:god_ch/features/admin/data/position_repository.dart';
import 'package:god_ch/features/auth/data/auth_repository.dart';
import 'package:god_ch/features/auth/data/profile_repository.dart';
import 'package:god_ch/features/bible/data/bible_repository.dart';
import 'package:god_ch/features/church/data/affiliation_repository.dart';
import 'package:god_ch/features/church/data/church_closure_repository.dart';
import 'package:god_ch/features/church/data/church_repository.dart';
import 'package:god_ch/features/church/data/church_request_repository.dart';
import 'package:god_ch/features/home/data/content_repository.dart';
import 'package:god_ch/features/home/data/reflection_repository.dart';
import 'package:god_ch/features/meetings/data/meeting_repository.dart';
import 'package:god_ch/features/members/data/member_repository.dart';
import 'package:god_ch/features/notifications/data/notification_repository.dart';
import 'package:god_ch/features/notifications/view/notifications_button.dart';
import 'package:god_ch/features/notifications/view/notifications_page.dart';
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

class _Bible extends Fake implements BibleRepository {}

class _Activity extends Fake implements ActivityLogRepository {}

class _Positions extends Fake implements PositionRepository {}

class _Members extends Fake implements MemberRepository {}

/// 메모리에 알림을 두는 가짜 저장소: 읽음 처리하면 목록이 다시 흘러나온다.
class _FakeNotifications extends Fake implements NotificationRepository {
  _FakeNotifications(this._items) {
    _push();
  }

  List<AppNotification> _items;
  final _list = StreamController<List<AppNotification>>.broadcast();
  final _count = StreamController<int>.broadcast();

  /// 읽음 처리를 요청받은 알림 아이디들.
  final markedRead = <String>[];

  /// 내 목록에서 숨긴 알림은 빼고 보여 준다 (실제 저장소와 같다).
  List<AppNotification> get _visible => [
    for (final n in _items)
      if (!n.hidden) n,
  ];

  int get unread => _items.where((n) => !n.read && !n.hidden).length;

  void _push() {
    _list.add(_visible);
    _count.add(unread);
  }

  void add(AppNotification n) {
    _items = [n, ..._items];
    _push();
  }

  @override
  Stream<List<AppNotification>> notifications() async* {
    yield _visible;
    yield* _list.stream;
  }

  @override
  Stream<int> unreadCount() async* {
    yield unread;
    yield* _count.stream;
  }

  @override
  Future<void> markRead(String id) async =>
      markAllRead(_items.where((n) => n.id == id));

  @override
  Future<void> markAllRead(Iterable<AppNotification> items) async {
    final ids = items.where((n) => !n.read).map((n) => n.id).toSet();
    if (ids.isEmpty) return;
    markedRead.addAll(ids);
    _items = [
      for (final n in _items) ids.contains(n.id) ? _copy(n, read: true) : n,
    ];
    _push();
  }

  @override
  Future<void> deleteMany(Iterable<String> ids) async {
    final set = ids.toSet();
    _items = [
      for (final n in _items)
        set.contains(n.id) ? _copy(n, read: true, hidden: true) : n,
    ];
    _push();
  }
}

AppNotification _copy(AppNotification n, {bool? read, bool? hidden}) =>
    AppNotification(
      id: n.id,
      title: n.title,
      body: n.body,
      type: n.type,
      read: read ?? n.read,
      createdAt: n.createdAt,
      hidden: hidden ?? n.hidden,
      churchId: n.churchId,
      meetingId: n.meetingId,
    );

AppNotification _joinRequest(String id, {bool read = false}) => AppNotification(
  id: id,
  title: '참여 신청 · 성경 공부',
  body: '김철수님이 승인을 기다리고 있어요.',
  type: NotificationType.meetingJoinRequest,
  read: read,
  createdAt: DateTime(2026, 11, 5),
  churchId: 'church1',
  meetingId: 'meeting1',
);

Widget _app(NotificationRepository notifications, Widget home) => AppScope(
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
  notifications: notifications,
  bible: _Bible(),
  activityLogs: _Activity(),
  child: MaterialApp(theme: buildTheme(Brightness.light), home: home),
);

Color? _colorOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void main() {
  group('알림 배지 글자', () {
    test('읽지 않은 알림 수를 보이고, 99를 넘으면 99+, 없으면 N', () {
      expect(notificationBadgeLabel(0), 'N');
      expect(notificationBadgeLabel(1), '1');
      expect(notificationBadgeLabel(12), '12');
      expect(notificationBadgeLabel(99), '99');
      expect(notificationBadgeLabel(100), '99+');
    });
  });

  group('모임 참여 신청 알림 내용', () {
    test('모임장이 눌러 그 모임을 열 수 있는 정보가 들어 있다', () {
      final meeting = Meeting(
        id: 'm1',
        title: '성경 공부',
        description: '',
        place: '본당',
        date: DateTime(2026, 12, 1),
        capacity: 8,
        leaderId: 'leader',
        leaderName: '모임장',
        needsApproval: true,
      );
      final doc = MeetingRepository.joinRequestNotification(
        churchId: 'c1',
        meeting: meeting,
        applicantName: '김철수',
      );
      expect(doc['type'], 'meetingJoinRequest');
      expect(doc['title'], contains('성경 공부'));
      expect(doc['body'], contains('김철수'));
      expect(doc['read'], false);
      expect(doc['churchId'], 'c1');
      expect(doc['meetingId'], 'm1');
      // firestore.rules가 허용하는 필드만 쓴다.
      expect(doc.keys.toSet(), {
        'type',
        'title',
        'body',
        'read',
        'churchId',
        'meetingId',
        'createdAt',
      });
    });

    test('이름이 없어도 알림 글이 비지 않는다', () {
      final meeting = Meeting(
        id: 'm1',
        title: '모임',
        description: '',
        place: '',
        date: DateTime(2026, 12, 1),
        capacity: 8,
        leaderId: 'leader',
        leaderName: '모임장',
        needsApproval: true,
      );
      final doc = MeetingRepository.joinRequestNotification(
        churchId: 'c1',
        meeting: meeting,
        applicantName: '',
      );
      expect((doc['body'] as String).isNotEmpty, isTrue);
    });
  });

  group('알림 버튼 배지', () {
    Future<void> pumpButton(
      WidgetTester tester,
      _FakeNotifications repo, {
      int pending = 0,
    }) async {
      await tester.pumpWidget(
        _app(
          repo,
          Scaffold(body: NotificationsButton(pendingRequests: pending)),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('읽지 않은 알림 수가 보이고 새 알림이 오면 늘어난다', (tester) async {
      final repo = _FakeNotifications([
        _joinRequest('a'),
        _joinRequest('b'),
        _joinRequest('c', read: true),
      ]);
      await pumpButton(tester, repo);
      expect(find.text('2'), findsOneWidget);

      repo.add(_joinRequest('d'));
      await tester.pump();
      await tester.pump();
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('모두 읽었고 처리할 요청도 없으면 배지가 없다', (tester) async {
      final repo = _FakeNotifications([_joinRequest('a', read: true)]);
      await pumpButton(tester, repo);
      expect(find.byType(Badge), findsOneWidget);
      expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);
    });

    testWidgets('알림이 없어도 처리할 입장 요청이 있으면 N', (tester) async {
      final repo = _FakeNotifications(const []);
      await pumpButton(tester, repo, pending: 2);
      expect(find.text('N'), findsOneWidget);
    });
  });

  group('알림 화면', () {
    Future<void> pumpPage(
      WidgetTester tester,
      _FakeNotifications repo, {
      void Function(String, String)? onOpenMeeting,
    }) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(repo, NotificationsPage(onOpenMeeting: onOpenMeeting)),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();
    }

    testWidgets('열어도 자동으로 읽음 처리되지 않고, 안 읽은 알림은 흐려지지 않는다', (tester) async {
      final repo = _FakeNotifications([_joinRequest('a')]);
      await pumpPage(tester, repo);

      expect(repo.markedRead, isEmpty);
      expect(repo.unread, 1);
      expect(find.text('참여 신청 · 성경 공부'), findsOneWidget);
      expect(_colorOf(tester, '참여 신청 · 성경 공부'), isNull);
    });

    testWidgets('알림을 누르면 읽음 처리되어 글씨가 흐려진다', (tester) async {
      final repo = _FakeNotifications([_joinRequest('a')]);
      await pumpPage(tester, repo);

      await tester.tap(find.text('참여 신청 · 성경 공부'));
      await tester.pump();
      await tester.pump();

      expect(repo.markedRead, ['a']);
      expect(_colorOf(tester, '참여 신청 · 성경 공부'), isNotNull);
    });

    testWidgets('모두 읽음을 누르면 읽지 않은 알림이 모두 읽음이 된다', (tester) async {
      final repo = _FakeNotifications([_joinRequest('a'), _joinRequest('b')]);
      await pumpPage(tester, repo);

      await tester.tap(find.text('모두 읽음'));
      await tester.pump();
      await tester.pump();

      expect(repo.unread, 0);
      expect(repo.markedRead.toSet(), {'a', 'b'});
    });

    testWidgets('화면을 보는 중에 새 알림이 오면 목록에 붙는다', (tester) async {
      final repo = _FakeNotifications(const []);
      await pumpPage(tester, repo);
      expect(find.text('알림이 없어요.'), findsOneWidget);

      repo.add(_joinRequest('b'));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('참여 신청 · 성경 공부'), findsOneWidget);
    });

    testWidgets('모임 신청 알림을 누르면 그 모임으로 연결된다', (tester) async {
      final repo = _FakeNotifications([_joinRequest('a', read: true)]);
      String? church;
      String? meeting;
      await pumpPage(
        tester,
        repo,
        onOpenMeeting: (c, m) {
          church = c;
          meeting = m;
        },
      );
      await tester.tap(find.text('참여 신청 · 성경 공부'));
      await tester.pumpAndSettle();
      expect(church, 'church1');
      expect(meeting, 'meeting1');
    });

    testWidgets('평소에는 줄에 체크박스가 없고, 삭제 모드에서 골라 지운다', (tester) async {
      final repo = _FakeNotifications([_joinRequest('a', read: true)]);
      await pumpPage(tester, repo);
      expect(find.byType(Checkbox), findsNothing);

      await tester.tap(find.text('삭제'));
      await tester.pump();
      expect(find.byType(Checkbox), findsOneWidget);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.text('삭제'));
      await tester.pump();
      await tester.pump();
      expect(find.text('참여 신청 · 성경 공부'), findsNothing);
      expect(find.byType(Checkbox), findsNothing);
    });
  });
}
