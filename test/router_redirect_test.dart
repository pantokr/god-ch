import 'package:god_ch/app/router.dart';
import 'package:god_ch/app/routes.dart';
import 'package:god_ch/app/session.dart';
import 'package:flutter_test/flutter_test.dart';

String? go(SessionStatus status, String location) =>
    sessionRedirect(status, Uri.parse(location));

void main() {
  group('로그인 상태별 주소 이동', () {
    test('확인 중에는 어떤 주소든 /loading으로 가고, 원래 주소를 기억한다', () {
      final r = go(SessionStatus.loading, '/churches/abc/prayers?dept=d1')!;
      expect(Uri.parse(r).path, Routes.loading);
      expect(
        Uri.parse(r).queryParameters['from'],
        '/churches/abc/prayers?dept=d1',
      );
      expect(go(SessionStatus.loading, Routes.loading), isNull);
    });

    test('로그인 전에는 로그인/가입만 볼 수 있다', () {
      expect(go(SessionStatus.signedOut, Routes.login), isNull);
      expect(go(SessionStatus.signedOut, Routes.signUp), isNull);
      final r = go(SessionStatus.signedOut, '/churches/abc/mine')!;
      expect(Uri.parse(r).path, Routes.login);
      expect(Uri.parse(r).queryParameters['from'], '/churches/abc/mine');
      // 기억할 주소가 없으면 from 없이 로그인으로.
      expect(go(SessionStatus.signedOut, '/'), Routes.login);
    });

    test('가입 정보가 필요하면 그 화면에 머문다', () {
      expect(go(SessionStatus.needsProfile, '/admin'), Routes.profile);
      expect(go(SessionStatus.needsProfile, Routes.profile), isNull);
    });

    test('회원: 시작/안내 화면에서 내 교회로 가고, 기억한 주소가 있으면 거기로 간다', () {
      expect(go(SessionStatus.member, '/'), Routes.churches);
      expect(go(SessionStatus.member, Routes.login), Routes.churches);
      expect(
        go(SessionStatus.member, '/loading?from=%2Fchurches%2Fabc%2Fmine'),
        '/churches/abc/mine',
      );
      expect(go(SessionStatus.member, '/churches/abc/prayers'), isNull);
    });

    test('회원은 운영자 패널에 들어갈 수 없다', () {
      expect(go(SessionStatus.member, '/admin'), Routes.churches);
      expect(go(SessionStatus.member, '/admin/users'), Routes.churches);
    });

    test('앱 운영자: 패널로 가고, 교회 안 화면에는 들어갈 수 없다', () {
      expect(go(SessionStatus.operator, '/'), Routes.admin);
      expect(go(SessionStatus.operator, Routes.login), Routes.admin);
      expect(go(SessionStatus.operator, '/churches'), Routes.admin);
      expect(go(SessionStatus.operator, '/churches/abc/prayers'), Routes.admin);
      expect(go(SessionStatus.operator, '/admin/churches/abc'), isNull);
    });

    test('다른 영역의 주소나 외부 주소는 돌아갈 곳으로 쓰지 않는다', () {
      // 회원이 /admin을 기억해 두었어도, 외부 주소를 from에 넣어도 무시한다.
      expect(
        go(SessionStatus.member, '/loading?from=%2Fadmin%2Fusers'),
        Routes.churches,
      );
      expect(
        go(SessionStatus.member, '/loading?from=https%3A%2F%2Fevil.example'),
        Routes.churches,
      );
      expect(
        go(SessionStatus.operator, '/loading?from=%2Fchurches%2Fabc'),
        Routes.admin,
      );
    });
  });

  group('주소 만들기', () {
    test('부서 전용 공간은 dept 쿼리로 구분한다', () {
      expect(Routes.section('c1', ChurchSection.feed), '/churches/c1/prayers');
      expect(
        Routes.section('c1', ChurchSection.feed, dept: 'd1'),
        '/churches/c1/prayers?dept=d1',
      );
      expect(ChurchSection.fromPath('mine'), ChurchSection.mine);
      expect(ChurchSection.fromPath('nope'), isNull);
    });

    test('운영자 패널 메뉴는 주소로 정해진다 (교회 상세는 교회 관리에 속한다)', () {
      expect(PlatformSection.fromPath('/admin'), PlatformSection.dashboard);
      expect(
        PlatformSection.fromPath('/admin/churches/abc'),
        PlatformSection.churches,
      );
      expect(PlatformSection.fromPath('/admin/users'), PlatformSection.users);
    });
  });
}
