import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:god_ch/app/preferences_controller.dart';
import 'package:god_ch/core/format.dart' as format;

void main() {
  final now = DateTime(2026, 11, 16, 12, 0, 0);
  String ago(Duration d) => format.fmtAgo(now.subtract(d), now: now);

  group('몇 분 전 표기', () {
    test('초 · 분 · 시간', () {
      expect(ago(const Duration(milliseconds: 300)), '방금 전');
      expect(ago(const Duration(seconds: 1)), '1초 전');
      expect(ago(const Duration(seconds: 59)), '59초 전');
      expect(ago(const Duration(seconds: 60)), '1분 전');
      expect(ago(const Duration(minutes: 59, seconds: 59)), '59분 전');
      expect(ago(const Duration(hours: 1)), '1시간 전');
      expect(ago(const Duration(hours: 23, minutes: 59)), '23시간 전');
    });

    test('일 · 주', () {
      expect(ago(const Duration(hours: 24)), '1일 전');
      expect(ago(const Duration(days: 6, hours: 23)), '6일 전');
      expect(ago(const Duration(days: 7)), '1주 전');
      expect(ago(const Duration(days: 13)), '1주 전');
      expect(ago(const Duration(days: 14)), '2주 전');
      expect(ago(const Duration(days: 27)), '3주 전');
    });

    test('4주가 지나면 날짜로 보인다', () {
      expect(ago(const Duration(days: 28)), '10.19');
      // 작년 이전은 연도가 붙는다.
      expect(format.fmtAgo(DateTime(2025, 3, 2, 9), now: now), '25.03.02');
    });

    test('미래 시각(서버 시각 확정 전)은 방금 전이다', () {
      expect(
        format.fmtAgo(now.add(const Duration(minutes: 3)), now: now),
        '방금 전',
      );
    });
  });

  group('일시 표기 설정', () {
    tearDown(() => format.dateStyle = format.DateStyle.relative);

    test('날짜를 고르면 글 · 댓글 시각이 날짜와 시각으로 보인다', () {
      final at = DateTime(2026, 11, 9, 14, 5);
      format.dateStyle = format.DateStyle.absolute;
      expect(format.fmtPosted(at, now: now), '11.09 14:05');
      format.dateStyle = format.DateStyle.relative;
      // 11.09 14:05 → 11.16 12:00은 7일이 안 된 6일 21시간이다.
      expect(format.fmtPosted(at, now: now), '6일 전');
    });

    test('값이 없으면 빈 문자열이다', () {
      expect(format.fmtPosted(null), '');
    });

    test('개인 설정이 표기를 저장하고 전역 표기를 맞춘다 (기본은 상대)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await PreferencesController.load();
      expect(prefs.dateStyle, format.DateStyle.relative);

      prefs.setDateStyle(format.DateStyle.absolute);
      expect(prefs.dateStyle, format.DateStyle.absolute);
      expect(format.dateStyle, format.DateStyle.absolute);

      // 저장된 값은 다시 열어도 유지되고, 열 때 전역 표기에 반영된다.
      format.dateStyle = format.DateStyle.relative;
      final reopened = await PreferencesController.load();
      expect(reopened.dateStyle, format.DateStyle.absolute);
      expect(format.dateStyle, format.DateStyle.absolute);
    });
  });
}
