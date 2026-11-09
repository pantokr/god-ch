import 'bible_books.dart';

/// 구절 제목의 책 이름을 줄임말로 보이는가 (개인 설정). false면 전체 이름이다.
/// 개인 설정이 바꾸고, [normalizeVerseTitle]이 읽는다.
bool useBookAbbreviation = false;

/// 성경 구절 제목을 한 가지 형식으로 맞춘다: "책이름 장:절" 또는 "책이름 장:시작-끝" (예: 창세기 1:1, 예레미야 29:11, 데살로니가후서 3:1-3).
/// 책 이름은 늘 전체 이름으로 쓴다. 받을 때는 줄임말(창) · 전체 이름(창세기) · 붙여 쓴 꼴(창1:1) · 버전 꼬리표(개역개정)를 모두 받아들인다.
/// 읽을 수 없는 제목은 그대로 돌려준다.
String normalizeVerseTitle(String raw) {
  final m = _pattern.firstMatch(raw.trim());
  if (m == null) return raw;
  final book = _bookIndex(m.group(1)!);
  if (book == null) return raw;
  final first = m.group(3)!;
  final last = m.group(4);
  final range = last == null || last == first ? first : '$first-$last';
  final name = useBookAbbreviation
      ? bibleBookAbbreviations[book]
      : bibleBooks[book];
  return '$name ${m.group(2)}:$range';
}

final _pattern = RegExp(
  r'^([가-힣]+)\s*(\d+)\s*[:장]\s*(\d+)\s*절?(?:\s*[-~–—]\s*(\d+)\s*절?)?(?:\s*\(.*\))?$',
);

int? _bookIndex(String name) {
  final full = bibleBooks.indexOf(name);
  if (full >= 0) return full;
  final abbr = bibleBookAbbreviations.indexOf(name);
  return abbr >= 0 ? abbr : null;
}

/// 입력한 구절 표기를 읽은 값. [chapter]는 1부터이고, 절을 쓰지 않았으면 [first] · [last]가 null이다 (장 전체).
class VerseRef {
  const VerseRef({
    required this.book,
    required this.chapter,
    this.first,
    this.last,
  });

  /// 책 번호 (0 = 창세기).
  final int book;
  final int chapter;
  final int? first;
  final int? last;
}

/// "요 3:16-18", "롬 8", "창세기1:1", "시편 23편" 같은 표기를 읽는다. 읽을 수 없으면 null.
/// 책 이름은 줄임말 · 전체 이름 모두 받고, 절을 쓰지 않으면 장 전체로 본다.
VerseRef? parseVerseRef(String raw) {
  final m = _refPattern.firstMatch(raw.trim());
  if (m == null) return null;
  final book = _bookIndex(m.group(1)!);
  if (book == null) return null;
  final chapter = int.tryParse(m.group(2)!);
  if (chapter == null || chapter < 1) return null;
  final first = int.tryParse(m.group(3) ?? '');
  final last = int.tryParse(m.group(4) ?? '');
  return VerseRef(
    book: book,
    chapter: chapter,
    first: first,
    last: last ?? first,
  );
}

final _refPattern = RegExp(
  r'^([가-힣]+)\s*(\d+)\s*[장편]?(?:\s*[:]\s*(\d+)\s*절?(?:\s*[-~–—]\s*(\d+)\s*절?)?)?\s*(?:\(.*\))?$',
);

/// 말씀 본문("절번호 본문" 줄들)에서 [show]가 false이면 맨 앞의 절 번호를 뺀다 (개인 설정의 절 번호 표시).
String displayVerseBody(String body, bool show) {
  if (show) return body;
  return body
      .split('\n')
      .map((l) => l.replaceFirst(RegExp(r'^\d+\s+'), ''))
      .join('\n');
}
