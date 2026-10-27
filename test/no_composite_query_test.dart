import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 기도 요청 조회가 복합 색인을 요구하지 않게 막는다.
/// where(같음)와 orderBy를 한 조회에 함께 쓰면 복합 색인이 필요해져
/// "The query requires an index" 오류가 난다. 최신순은 글 ID(시간 역순)로 얻는다.
void main() {
  test('기도 요청 저장소는 where와 orderBy를 한 조회에 함께 쓰지 않는다', () {
    final source = File('lib/features/prayers/data/prayer_repository.dart')
        .readAsStringSync();
    // 주석은 뺀다.
    final code = source
        .split('\n')
        .where((l) => !l.trimLeft().startsWith('//'))
        .join('\n');
    final bad = [
      for (final statement in code.split(';'))
        if (statement.contains('.where(') && statement.contains('.orderBy('))
          statement.trim().split('\n').first,
    ];
    expect(bad, isEmpty, reason: '복합 색인이 필요한 조회: $bad');
  });

  test('색인 설정 파일에 복합 색인이 없다', () {
    final text = File('firestore.indexes.json').readAsStringSync();
    expect(RegExp(r'"indexes"\s*:\s*\[\s*\]').hasMatch(text), isTrue);
  });
}
