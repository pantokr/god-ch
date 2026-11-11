import 'package:god_ch/data/models/church.dart';
import 'package:god_ch/data/models/activity_log.dart';
import 'package:god_ch/features/platform/view/activity_log_page.dart';
import 'package:god_ch/core/icons.dart';
import 'package:god_ch/features/activity/data/activity_log_repository.dart';
import 'package:god_ch/features/auth/view/sign_up_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:god_ch/app/app_scope.dart';
import 'package:god_ch/app/list_style_controller.dart';
import 'package:god_ch/app/preferences_controller.dart';
import 'package:god_ch/app/theme_mode_controller.dart';
import 'package:god_ch/core/layout/manage_list_row.dart';
import 'package:god_ch/core/theme.dart';
import 'package:god_ch/core/widgets/expandable_text.dart';
import 'package:god_ch/core/widgets/view_mode_toggle.dart';
import 'package:god_ch/data/models/affiliation.dart';
import 'package:god_ch/data/models/member.dart';
import 'package:god_ch/data/models/church_content.dart';
import 'package:god_ch/core/widgets/shadow_switch.dart';
import 'package:god_ch/features/meetings/view_model/my_meetings_view_model.dart';
import 'package:god_ch/features/home/view/post_meta.dart';
import 'package:god_ch/core/widgets/role_chips.dart';
import 'package:god_ch/features/bible/view/verse_card.dart';
import 'package:god_ch/features/shell/view/preferences_page.dart';
import 'package:god_ch/features/home/view_model/affiliation_choice.dart';
import 'package:god_ch/features/bible/view/bible_page.dart' show BiblePage;
import 'package:god_ch/data/models/devotion_settings.dart';
import 'package:god_ch/data/models/position.dart';
import 'package:god_ch/data/models/prayer.dart';
import 'package:god_ch/data/models/prayer_settings.dart';
import 'package:god_ch/data/models/reaction.dart';
import 'package:god_ch/features/bible/view/bible_page.dart' show DevotionCard;
import 'package:god_ch/features/prayers/view/prayer_board_page.dart'
    show PrayerTile;
import 'package:god_ch/features/admin/data/position_repository.dart';
import 'package:god_ch/features/admin/view/affiliation_manage_page.dart';
import 'package:god_ch/features/admin/view/church_members_tab.dart';
import 'package:god_ch/features/admin/view/position_manage_page.dart';
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
import 'package:god_ch/features/people/data/people_repository.dart';
import 'package:god_ch/features/platform/data/church_registry_repository.dart';
import 'package:god_ch/features/prayers/data/prayer_repository.dart';

class _Auth extends Fake implements AuthRepository {}

class _Profiles extends Fake implements ProfileRepository {}

class _Churches extends Fake implements ChurchRepository {}

class _Requests extends Fake implements ChurchRequestRepository {}

class _Registry extends Fake implements ChurchRegistryRepository {
  @override
  Stream<List<Church>> churches() => Stream.value([
    const Church(id: 'c1', name: '은혜교회', phone: '', address: ''),
  ]);
}

class _Closures extends Fake implements ChurchClosureRepository {}

class _Affs extends Fake implements AffiliationRepository {
  @override
  Stream<List<Affiliation>> affiliations(String churchId) =>
      Stream.value(const [
        Affiliation('a1', '청년회'),
        Affiliation('a2', '아주 긴 이름의 소속 모임 이름이 카드에 들어갑니다'),
      ]);
}

class _Contents extends Fake implements ContentRepository {
  @override
  Stream<List<ChurchContent>> latest(
    String churchId, {
    int limit = 30,
    bool includePrivate = false,
    List<String>? affiliationIds,
  }) => Stream.value([
    ChurchContent(
      id: 'd1',
      kind: ContentKind.devotion,
      title: '창1:1',
      body: '1 태초에',
      date: DateTime.now(),
      meditation: '묵상 내용이 열 글자 이상입니다.',
      authorId: 'x',
      authorName: '작성자',
      affiliationId: 'a1',
      createdAt: DateTime.now(),
      extras: const [
        DevotionPassage(
          title: '요 3:16',
          body: '16 하나님이',
          meditation: '두 번째 묵상입니다 충분히',
        ),
      ],
    ),
  ]);

  @override
  Stream<DevotionSettings> settings(String churchId) =>
      Stream.value(DevotionSettings.standard);
}

class _Reflections extends Fake implements ReflectionRepository {
  @override
  Stream<int> count(String churchId, String devotionId) => Stream.value(12);
}

class _Meetings extends Fake implements MeetingRepository {}

class _People extends Fake implements PeopleRepository {
  @override
  ValueListenable<Map<String, String>> photos(String churchId) =>
      ValueNotifier(const {});
}

class _Prayers extends Fake implements PrayerRepository {
  @override
  Stream<ReactionSummary> reactions(String churchId, String prayerId) =>
      Stream.value(ReactionSummary.empty);

  @override
  Stream<int> commentCount(String churchId, String prayerId) => Stream.value(7);
}

class _Notifications extends Fake implements NotificationRepository {}

class _Bible extends Fake implements BibleRepository {}

class _Activity extends Fake implements ActivityLogRepository {
  static final items = [
    ActivityLog(
      id: '1',
      uid: 'u1',
      userName: '김성도',
      type: ActivityType.login,
      at: DateTime(2026, 11, 11, 9, 30),
    ),
    ActivityLog(
      id: '2',
      uid: 'u2',
      userName: '이집사',
      type: ActivityType.meetingCreate,
      churchId: 'c1',
      summary: '성경 공부 모임을 아주 길게 이어서 쓴 제목',
      at: DateTime(2026, 11, 11, 9, 31),
    ),
  ];
  final requested = <String>[];

  @override
  Stream<List<ActivityLog>> recent({int limit = 200}) {
    requested.add('recent/$limit');
    return Stream.value(items);
  }

  @override
  Stream<List<ActivityLog>> byUser(String uid, {int limit = 200}) {
    requested.add('byUser/$uid/$limit');
    return Stream.value([
      for (final l in items)
        if (l.uid == uid) l,
    ]);
  }
}

class _Positions extends Fake implements PositionRepository {
  @override
  Stream<List<Position>> positions(String churchId) => Stream.value(const [
    Position(id: 'p1', name: '찬양팀', permissions: {'prayer.write'}),
  ]);
}

class _Members extends Fake implements MemberRepository {
  @override
  Future<void> syncAdminAffiliations(String churchId) async {}

  @override
  Stream<List<Member>> members(String churchId) => Stream.value([
    const Member(
      id: 'm1',
      churchId: 'c',
      churchName: '교회',
      name: '아주긴이름을가진교인이름',
      role: Role.staff,
      status: MemberStatus.approved,
      loginId: 'verylongloginid',
      affiliationIds: ['a1', 'a2'],
      positionId: 'p1',
    ),
    const Member(
      id: 'm2',
      churchId: 'c',
      churchName: '교회',
      name: '홍길동',
      role: Role.member,
      status: MemberStatus.approved,
    ),
    Member(
      id: 'm3',
      churchId: 'c',
      churchName: '교회',
      name: '입장신청자',
      role: Role.member,
      status: MemberStatus.pending,
      loginId: 'newcomer',
      phone: '010-1234-5678',
      affiliationIds: const ['a1'],
      createdAt: DateTime(2026, 11, 9, 14, 30),
    ),
  ]);
}

const _me = Member(
  id: 'u',
  churchId: 'c',
  churchName: '교회',
  name: '관리자',
  role: Role.admin,
  status: MemberStatus.approved,
);

/// 앱이 쓰는 글씨 배율: 폰(좁은 화면)은 1.08, 와이드는 1.18에 개인 설정 배율(작게 0.92 · 보통 1.0 · 크게 1.12)을 곱한다.
final _cases = <(String, double, double)>[
  for (final size in TextSize.values) ...[
    ('폰 · ${size.label}', 390, 1.08 * size.factor),
    ('와이드 · ${size.label}', 1000, 1.18 * size.factor),
  ],
];

Widget _scoped(Widget child, double scale, [PreferencesController? prefs]) =>
    AppScope(
      themeMode: ThemeModeController(null),
      listStyle: ListStyleController(null),
      preferences: prefs ?? PreferencesController(null),
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
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(body: child),
      ),
    );

Future<void> _pump(
  WidgetTester tester,
  Widget child,
  double width,
  double scale, [
  PreferencesController? prefs,
]) async {
  tester.view.physicalSize = Size(width, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_scoped(child, scale, prefs));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void _noop() {}

void main() {
  for (final (name, width, scale) in _cases) {
    group('글씨 크기 $name (배율 ${scale.toStringAsFixed(2)})', () {
      testWidgets('소속 관리 카드(미배정 포함)가 넘치지 않는다', (tester) async {
        await _pump(tester, const AffiliationManagePage(me: _me), width, scale);
        expect(tester.takeException(), isNull);
      });

      testWidgets('회원 관리 목록 줄이 넘치지 않는다', (tester) async {
        await _pump(tester, const ChurchMembersTab(me: _me), width, scale);
        expect(tester.takeException(), isNull);
      });

      testWidgets('입장 요청 줄을 누르면 그 사람의 상세 정보가 열린다', (tester) async {
        await _pump(tester, const ChurchMembersTab(me: _me), width, scale);
        await tester.tap(find.textContaining('입장신청자'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
        expect(find.text('010-1234-5678'), findsOneWidget);
        expect(find.text('newcomer'), findsOneWidget);
        expect(find.text('승인 대기'), findsOneWidget);
        expect(find.text('요청일'), findsOneWidget);
        // 상세 페이지는 보기만 한다: 역할 · 상태를 고치는 칸이 없다.
        expect(find.text('저장'), findsNothing);
      });

      testWidgets('회원가입 화면이 넘치지 않고 입력 묶음이 모두 보인다', (tester) async {
        await _pump(tester, const SignUpPage(), width, scale);
        expect(tester.takeException(), isNull);
        expect(find.text('회원가입'), findsOneWidget);
        expect(find.text('로그인 정보'), findsOneWidget);
        expect(find.text('기본 정보'), findsOneWidget);
        expect(find.text('추가 정보 (선택)'), findsOneWidget);
      });

      testWidgets('개인정보 동의: 줄을 누르면 체크되고 내용 보기에서 바로 동의한다', (tester) async {
        await _pump(tester, const SignUpPage(), width, scale);
        bool checked() =>
            find.byIcon(AppIcons.checkCircleFill).evaluate().isNotEmpty;
        await tester.ensureVisible(find.text('전체 내용 보기'));
        await tester.pump();
        await tester.tap(
          find.textContaining('개인정보 제3자 제공 동의', findRichText: true),
        );
        await tester.pump();
        expect(checked(), isTrue);
        await tester.tap(
          find.textContaining('개인정보 제3자 제공 동의', findRichText: true),
        );
        await tester.pump();
        expect(checked(), isFalse);
        await tester.tap(find.text('전체 내용 보기'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
        expect(find.text('제공받는 자'), findsOneWidget);
        await tester.tap(find.text('동의'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(checked(), isTrue);
        expect(tester.takeException(), isNull);
      });

      testWidgets('활동 기록 화면이 넘치지 않고, 줄을 누르면 그 회원만 본다', (tester) async {
        await _pump(tester, const ActivityLogPage(), width, scale);
        expect(tester.takeException(), isNull);
        expect(find.text('김성도 · 로그인'), findsOneWidget);
        expect(find.text('이집사 · 모임 만들기'), findsOneWidget);
        expect(find.textContaining('은혜교회 · 성경 공부'), findsOneWidget);
        await tester.tap(find.text('김성도 · 로그인'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        expect(find.text('이집사 · 모임 만들기'), findsNothing);
      });

      testWidgets('직급 관리가 넘치지 않는다', (tester) async {
        await _pump(tester, const PositionManagePage(me: _me), width, scale);
        expect(tester.takeException(), isNull);
      });

      testWidgets('교회 관리자 인원 창이 오류 없이 열린다', (tester) async {
        await _pump(tester, const PositionManagePage(me: _me), width, scale);
        await tester.tap(find.byTooltip('인원').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
        expect(find.text('교회 관리자 인원'), findsOneWidget);
      });

      testWidgets('직급 수정 페이지(권한명 · 범위 나열)가 넘치지 않는다', (tester) async {
        await _pump(tester, const PositionManagePage(me: _me), width, scale);
        // 직접 만든 직급(찬양팀)의 연필을 눌러 수정 페이지를 연다.
        await tester.tap(find.byTooltip('수정').at(2));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
        expect(find.text('범위'), findsNothing);
        expect(find.text('전체 게시물'), findsWidgets);
        expect(find.text('본인 게시물'), findsWidgets);
      });

      testWidgets('관리 목록 줄(이름 · 표시 · 칩 · 버튼)이 넘치지 않는다', (tester) async {
        await _pump(
          tester,
          Column(
            children: [
              Builder(
                builder: (context) => ManageListRow(
                  leading: ManageListRow.avatar(context, '가'),
                  title: '아주 긴 이름을 가진 교인의 이름이 여기에 들어갑니다 (verylongid)',
                  badge: '본인',
                  line1: '요청일 11.09',
                  affiliations: const ['청년회', '장년회', '풋살모임'],
                  trailing: [
                    TextButton(onPressed: () {}, child: const Text('관리')),
                    TextButton(onPressed: () {}, child: const Text('삭제')),
                  ],
                ),
              ),
            ],
          ),
          width,
          scale,
        );
        expect(tester.takeException(), isNull);
      });

      for (final grid in [false, true]) {
        testWidgets('중보기도 · 말씀묵상 카드(${grid ? '그리드' : '리스트'})가 넘치지 않는다', (
          tester,
        ) async {
          final prayers = [
            for (final long in [false, true])
              PrayerTile(
                prayer: Prayer(
                  id: 'p${long ? 1 : 0}',
                  authorId: 'x',
                  authorName: '긴이름을가진작성자',
                  content: long ? '기도 제목이 아주 길어서 여러 줄로 넘어갑니다. ' * 8 : '짧은 기도',
                  visibility: PrayerVisibility.private,
                  deleted: false,
                  affiliationId: 'a1',
                  createdAt: DateTime.now(),
                ),
                me: _me,
                settings: PrayerSettings.standard,
                affiliationNames: const {'a1': '청년회'},
                gutter: grid ? 0 : null,
                grid: grid,
              ),
          ];
          final devotions = [
            for (final extras in [0, 3])
              DevotionCard(
                content: ChurchContent(
                  id: 'd$extras',
                  kind: ContentKind.devotion,
                  title: '데살로니가후서 3:1-3',
                  body: '1 본문',
                  date: DateTime.now(),
                  meditation: '묵상 내용이 길게 이어집니다. ' * 10,
                  visibility: 'private',
                  authorId: 'x',
                  authorName: '작성자',
                  affiliationId: 'a1',
                  createdAt: DateTime.now(),
                ),
                me: _me,
                settings: DevotionSettings.standard,
                affiliationNames: const {'a1': '청년회'},
                gutter: grid ? 0 : null,
                grid: grid,
              ),
          ];
          final cards = [...prayers, ...devotions];
          await _pump(
            tester,
            SingleChildScrollView(
              child: grid
                  ? TwoColumn(children: cards)
                  : Column(children: cards),
            ),
            width,
            scale,
          );
          expect(tester.takeException(), isNull);
        });
      }

      testWidgets('말씀묵상 화면이 오류 없이 열린다', (tester) async {
        await _pump(
          tester,
          SizedBox(
            height: 2000,
            child: BiblePage(me: _me, choice: AffiliationChoice()),
          ),
          width,
          scale,
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      });

      testWidgets('색을 바꾼 뒤에도 말씀묵상 화면이 오류 없이 열린다', (tester) async {
        SharedPreferences.setMockInitialValues({
          'tint_bible': 'sand',
          'size_bible': 'large',
        });
        final prefs = PreferencesController(
          await SharedPreferences.getInstance(),
        );
        await _pump(
          tester,
          SizedBox(
            height: 2000,
            child: BiblePage(me: _me, choice: AffiliationChoice()),
          ),
          width,
          scale,
          prefs,
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      });

      testWidgets('개인 설정의 말씀묵상 카드 색이 카드에 반영된다', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = PreferencesController(
          await SharedPreferences.getInstance(),
        );
        final card = DevotionCard(
          content: ChurchContent(
            id: 'dt',
            kind: ContentKind.devotion,
            title: '데살로니가후서 3:1-3',
            body: '1 본문',
            date: DateTime.now(),
            meditation: '묵상',
            visibility: 'public',
            authorId: 'x',
            authorName: '작성자',
            createdAt: DateTime.now(),
          ),
          me: _me,
          settings: DevotionSettings.standard,
          affiliationNames: const {},
        );
        await _pump(tester, card, width, scale, prefs);
        Color? inkColor() {
          for (final w in tester.widgetList<Ink>(find.byType(Ink))) {
            final d = w.decoration;
            if (d is BoxDecoration && d.color != null) return d.color;
          }
          return null;
        }

        final before = inkColor();
        prefs.setTint('bible', ScreenTint.sand);
        await tester.pump();
        expect(inkColor(), ScreenTint.sand.colorFor(Brightness.light));
        expect(inkColor(), isNot(before));
      });

      testWidgets('개인 설정 화면이 넘치지 않는다 (미리보기 · 신규 표시 · 글꼴 없음)', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = PreferencesController(
          await SharedPreferences.getInstance(),
        );
        await _pump(
          tester,
          const SingleChildScrollView(child: PreferencesPage()),
          width,
          scale,
          prefs,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('디자인'), findsOneWidget);
        expect(find.text('신규 표시'), findsNothing);
        expect(find.text('글꼴'), findsNothing);
        expect(find.text('본문 글꼴'), findsNothing);
      });

      testWidgets('개인 설정: 글씨 크기 카드는 크기가 같고 2 · 3개 라디오와 같은 열에 놓인다', (
        tester,
      ) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = PreferencesController(
          await SharedPreferences.getInstance(),
        );
        await _pump(
          tester,
          const SingleChildScrollView(child: PreferencesPage()),
          width,
          scale,
          prefs,
        );
        expect(tester.takeException(), isNull);

        // 카드(테두리 상자): 글자 '가' 바로 바깥의 DecoratedBox.
        Finder tile(int i) => find
            .ancestor(
              of: find.text('가').at(i),
              matching: find.byType(DecoratedBox),
            )
            .first;
        final sizes = [for (var i = 0; i < 3; i++) tester.getSize(tile(i))];
        expect(sizes[0].height, lessThan(160), reason: '카드 하나의 높이여야 한다');
        for (final s in sizes) {
          expect(s.width, sizes[0].width, reason: '글씨 크기 카드 폭이 같다');
          expect(s.height, sizes[0].height, reason: '글씨 크기 카드 높이가 같다');
        }

        // 같은 열: 2개 줄(책 이름) · 3개 줄(디자인) · 글씨 크기 카드의 두 번째 칸이 같은 x에서 시작한다.
        final second2 = tester.getTopLeft(find.byType(Radio<bool>).at(1)).dx;
        final second3 = tester
            .getTopLeft(find.byType(Radio<DevotionDesign>).at(1))
            .dx;
        final secondTile = tester.getTopLeft(tile(1)).dx;
        expect(second2, closeTo(second3, 0.5), reason: '2개 줄과 3개 줄이 어긋남');
        expect(secondTile, closeTo(second3, 0.5), reason: '글씨 크기 카드가 라디오와 어긋남');
      });

      testWidgets('절 번호 · 말씀 디자인 설정이 말씀 본문 카드에 반영된다', (tester) async {
        for (final design in DevotionDesign.values) {
          for (final numbers in [true, false]) {
            SharedPreferences.resetStatic();
            SharedPreferences.setMockInitialValues({
              'verse_numbers': numbers,
              'design_bible': design.name,
            });
            final prefs = PreferencesController(
              await SharedPreferences.getInstance(),
            );
            await _pump(
              tester,
              // 설정이 바뀐 뒤에는 새로 그려야 해서 매번 다른 키를 준다.
              VerseCard(
                key: UniqueKey(),
                title: '시편 23:1',
                body: '1 여호와는 나의 목자시니',
              ),
              width,
              scale,
              prefs,
            );
            expect(tester.takeException(), isNull, reason: '$design');
            expect(
              find.text(numbers ? '1 여호와는 나의 목자시니' : '여호와는 나의 목자시니'),
              findsOneWidget,
              reason: '$design 절 번호 $numbers',
            );
          }
        }
      });

      testWidgets('일정 공개 범위 소속 칩(표시 · 선택)이 넘치지 않는다', (tester) async {
        var picked = false;
        await _pump(
          tester,
          StatefulBuilder(
            builder: (context, setState) => Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AffiliationChips([
                    '청년회',
                    '아주 긴 이름의 소속 모임 이름이 카드에 들어갑니다',
                    '장년회',
                  ]),
                  const AffiliationChips([]),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      AffiliationChoiceChip(
                        label: '아주 긴 이름의 소속 모임 이름이 카드에 들어갑니다',
                        selected: picked,
                        onTap: () => setState(() => picked = !picked),
                      ),
                      const AffiliationChoiceChip(
                        label: '청년회',
                        selected: true,
                        onTap: _noop,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          width,
          scale,
        );
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
        expect(find.text('전체'), findsOneWidget);
        await tester.tap(find.byType(AffiliationChoiceChip).first);
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        expect(picked, isTrue);
      });

      testWidgets('명조는 말씀 본문 한 군데에만 쓰이고 나머지는 고딕이다', (tester) async {
        late BuildContext inner;
        await _pump(
          tester,
          Builder(
            builder: (context) {
              inner = context;
              return Column(
                children: [
                  // 말씀 본문 카드: 명조.
                  VerseCard(
                    key: UniqueKey(),
                    title: '시편 23:1',
                    body: '1 여호와는 나의 목자시니',
                  ),
                  // 묵상 · 기도 같은 긴 글: 고딕.
                  Text('묵상', style: readingStyle(context)),
                ],
              );
            },
          ),
          width,
          scale,
        );
        expect(tester.takeException(), isNull);
        expect(verseTextStyle(inner).fontFamily, contains('Serif'));
        expect(
          readingStyle(inner).fontFamily ?? 'Pretendard',
          isNot(contains('Serif')),
        );
        // 말씀 본문 글자만 명조다.
        final verse = tester.widget<ExpandableText>(
          find.byType(ExpandableText),
        );
        expect(verse.style?.fontFamily, contains('Serif'));
        final meditation = tester.widget<Text>(find.text('묵상'));
        expect(
          meditation.style?.fontFamily ?? 'Pretendard',
          isNot(contains('Serif')),
        );
      });

      testWidgets('상세 정보 줄의 라벨과 값이 좌우로 맞닿지 않는다', (tester) async {
        await _pump(
          tester,
          const Padding(
            padding: EdgeInsets.all(16),
            child: PostMeta(
              churchId: 'c',
              date: '2026.11.09 10:00',
              isPrivate: true,
              views: 12,
            ),
          ),
          width,
          scale,
        );
        expect(tester.takeException(), isNull);
        for (final (label, value) in [
          ('작성일', '2026.11.09 10:00'),
          ('조회수', '12회'),
          ('공개 여부', '교역자 전용'),
        ]) {
          // 라벨 글자가 실제로 차지하는 오른쪽 끝(칸 너비가 아니라 글자 너비)과 값의 왼쪽 끝.
          final paragraph = tester.renderObject<RenderParagraph>(
            find.text(label),
          );
          final labelRight =
              tester.getTopLeft(find.text(label)).dx +
              paragraph.getMaxIntrinsicWidth(double.infinity);
          final valueLeft = tester.getTopLeft(find.text(value)).dx;
          expect(
            valueLeft - labelRight,
            greaterThanOrEqualTo(4),
            reason: '$label · $value',
          );
        }
      });

      testWidgets('내 일정 스위치(참여 예정 · 관심 일정 · 참여 완료)가 넘치지 않는다', (tester) async {
        var selected = MyMeetingView.upcoming;
        await _pump(
          tester,
          StatefulBuilder(
            builder: (context, setState) => Padding(
              padding: const EdgeInsets.all(16),
              child: ShadowSwitch<MyMeetingView>(
                values: const [
                  MyMeetingView.upcoming,
                  MyMeetingView.liked,
                  MyMeetingView.attended,
                ],
                selected: selected,
                onChanged: (v) => setState(() => selected = v),
                labelOf: (v) => v.label,
              ),
            ),
          ),
          width,
          scale,
        );
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('참여 완료'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(selected, MyMeetingView.attended);
        expect(tester.takeException(), isNull);
      });

      testWidgets('더보기 글과 4열 그리드가 넘치지 않는다', (tester) async {
        await _pump(
          tester,
          SingleChildScrollView(
            child: Column(
              children: [
                ExpandableText('말씀 본문 ' * 120, maxLines: 6),
                TwoColumn(
                  children: [
                    for (var i = 0; i < 7; i++)
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.white,
                        child: const Text('카드 제목이 조금 긴 편입니다 카드 제목'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          width,
          scale,
        );
        expect(tester.takeException(), isNull);
      });
    });
  }
}
