import 'package:flutter_test/flutter_test.dart';
import 'package:god_ch/data/bible_reference.dart';

void main() {
  test('구절 제목을 책 이름과 장 · 절로 나눈다', () {
    expect(splitVerseTitle('요한복음 3:16'), ('요한복음', '3장 16절'));
    expect(splitVerseTitle('데살로니가후서 3:1-3'), ('데살로니가후서', '3장 1-3절'));
    // 줄임말과 붙여 쓴 꼴도 전체 이름으로 맞춰 나눈다.
    expect(splitVerseTitle('요 3:16'), ('요한복음', '3장 16절'));
  });

  test('읽을 수 없는 제목은 null이다', () {
    expect(splitVerseTitle('오늘의 말씀'), isNull);
    expect(splitVerseTitle(''), isNull);
  });
}
