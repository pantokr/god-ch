import 'package:flutter_test/flutter_test.dart';
import 'package:god_ch/data/bible_reference.dart';

void main() {
  test('구절 제목은 늘 전체 책 이름의 한 가지 형식이다', () {
    expect(normalizeVerseTitle('창1:1'), '창세기 1:1');
    expect(normalizeVerseTitle('예레미야 29:11'), '예레미야 29:11');
    expect(normalizeVerseTitle('빌 4:6-7'), '빌립보서 4:6-7');
    expect(normalizeVerseTitle('살후 3:1-3 (개역개정)'), '데살로니가후서 3:1-3');
    expect(normalizeVerseTitle('알 수 없는 제목'), '알 수 없는 제목');
  });

  test('구절 입력은 책 · 장 · 절 범위로 읽힌다', () {
    final a = parseVerseRef('요 3:16-18')!;
    expect((a.book, a.chapter, a.first, a.last), (42, 3, 16, 18));
    final b = parseVerseRef('롬 8')!;
    expect((b.book, b.chapter, b.first, b.last), (44, 8, null, null));
    final c = parseVerseRef('시편 23편')!;
    expect((c.book, c.chapter), (18, 23));
    expect(parseVerseRef('없는책 1:1'), isNull);
    expect(parseVerseRef(''), isNull);
  });
}
