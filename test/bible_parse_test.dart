import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:god_ch/features/bible/data/bible_repository.dart';

void main() {
  test('verse.csv를 읽어 구절을 찾는다', () {
    final file = File('data/bible/bible_verses.csv');
    if (!file.existsSync()) return;
    final bible = BibleRepository.parse(file.readAsBytesSync());
    // 요한복음 3:16 (책 42, 장 2, 절 15)
    expect(bible.chapterCount(42), 21);
    final v = bible.verses(42, 2)[15];
    expect(v.text(BibleVersion.gae), contains('독생자'));
    expect(
      bible.verses(0, 0).first.text(BibleVersion.kjv),
      startsWith('In the beginning'),
    );
  });
}
