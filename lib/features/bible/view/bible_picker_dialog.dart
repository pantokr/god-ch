import '../../../core/widgets/app_loader.dart';

import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/icons.dart';
import '../../../core/layout/app_dialog.dart';
import '../../../core/theme.dart';
import '../../../data/bible_books.dart';
import '../../../data/bible_reference.dart';
import '../data/bible_repository.dart';

/// 고른 구절: 제목(예: 요한복음 3:16-18 (개역개정))과 절 번호가 붙은 본문.
class BiblePick {
  const BiblePick({required this.title, required this.body});

  final String title;
  final String body;
}

/// 말씀묵상에 넣을 성경 구절을 고른다: 번역 · 책 · 장 · 시작 절 · 끝 절.
/// 성경 본문은 앱 운영자가 올려 둔 Storage 파일에서 가져온다.
class BiblePickerDialog extends StatefulWidget {
  const BiblePickerDialog({super.key, this.initialTitle = ''});

  /// 이미 고른 구절의 이름(예: 롬 8:1-39). 있으면 창이 열릴 때 그 구절이 골라져 있다 (수정할 때).
  final String initialTitle;

  @override
  State<BiblePickerDialog> createState() => _BiblePickerDialogState();
}

class _BiblePickerDialogState extends State<BiblePickerDialog> {
  late final Future<Bible> _bible = AppScope.read(context).bible.load();

  BibleVersion _version = BibleVersion.gae;
  int _book = 0;
  int _chapter = 0;
  int _from = 0;
  // 기본은 그 장의 모든 절이다 (-1이면 아직 정하지 않음: 성경을 불러온 뒤 마지막 절로 채운다).
  int _to = -1;
  bool _started = false;
  Bible? _loaded;
  final _ref = TextEditingController();

  @override
  void dispose() {
    _ref.dispose();
    super.dispose();
  }

  /// 구절 표기를 적용한다: 책 · 장 · 절 범위가 그 값으로 바뀐다 (범위를 벗어나면 맞는 만큼으로 줄인다).
  void _apply(Bible bible, VerseRef ref) {
    _book = ref.book;
    _chapter = (ref.chapter - 1).clamp(0, bible.chapterCount(_book) - 1);
    final count = _verses(bible).length;
    if (count == 0) return;
    if (ref.first == null) {
      _from = 0;
      _to = count - 1;
    } else {
      _from = (ref.first! - 1).clamp(0, count - 1);
      _to = ((ref.last ?? ref.first!) - 1).clamp(_from, count - 1);
    }
  }

  /// 책 이름 격자에서 책을 고른다.
  Future<void> _pickBook(Bible bible) async {
    final book = await showAppDialog<int>(
      context,
      maxWidth: 520,
      child: _BookGrid(selected: _book),
    );
    if (book == null) return;
    setState(() {
      _book = book;
      _chapter = 0;
      _resetRange(bible);
      _ref.clear();
    });
  }

  List<BibleVerse> _verses(Bible bible) => bible.verses(_book, _chapter);

  void _resetRange(Bible bible) {
    final count = _verses(bible).length;
    _from = 0;
    // 책이나 장을 고르면 그 장의 모든 절이 선택된다.
    _to = count == 0 ? 0 : count - 1;
  }

  BiblePick _pick(Bible bible) {
    final verses = _verses(bible);
    final chosen = verses.sublist(_from, _to + 1);
    final first = chosen.first.verse + 1;
    final last = chosen.last.verse + 1;
    final range = first == last ? '$first' : '$first-$last';
    return BiblePick(
      // 책 이름은 전체 이름, 형식은 늘 "책 장:절"이다 (예: 데살로니가후서 3:1-3).
      title: '${bibleBooks[_book]} ${_chapter + 1}:$range',
      body: [
        for (final v in chosen) '${v.verse + 1} ${v.text(_version).trim()}',
      ].join('\n'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Bible>(
      future: _bible,
      builder: (context, snap) {
        if (snap.hasError) {
          return _Message(
            title: '성경 본문을 불러오지 못했어요',
            body:
                '${snap.error}\n\nStorage에 성경 파일(bible/verse.csv)이 있는지, '
                '그리고 Storage에 CORS 설정(tool/cors.json)이 적용됐는지 확인해 주세요.',
          );
        }
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [AppLoader(), SizedBox(height: 16), Text('불러오는 중')],
            ),
          );
        }
        final bible = snap.data!;
        _loaded = bible;
        // 수정할 때는 지금 올라가 있는 구절이 처음부터 골라져 있다.
        if (!_started) {
          _started = true;
          final initial = parseVerseRef(widget.initialTitle);
          if (initial != null) {
            _apply(bible, initial);
            _ref.text = widget.initialTitle;
          }
        }
        final verses = _verses(bible);
        if (_to < 0) _to = verses.isEmpty ? 0 : verses.length - 1;
        final chapters = bible.chapterCount(_book);
        final palette = context.palette;
        final pick = verses.isEmpty ? null : _pick(bible);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 책 · 장 · 절 선택: 테두리 있는 칸 하나에 모은다.
            DecoratedBox(
              decoration: BoxDecoration(
                color: palette.surface,
                border: Border.all(color: context.cardEdge),
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 구절을 바로 쓰면 아래 책 · 장 · 절이 그 값으로 바뀐다 (예: 요 3:16-18, 롬 8).
                    TextField(
                      controller: _ref,
                      decoration: InputDecoration(
                        labelText: '구절 입력',
                        hintText: '예: 요 3:16-18',
                        prefixIcon: Icon(AppIcons.magnifyingGlass, size: 18),
                      ),
                      onChanged: (v) {
                        final ref = parseVerseRef(v);
                        final b = _loaded;
                        if (ref != null && b != null) {
                          setState(() => _apply(b, ref));
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          // 책: 66권을 목록으로 찾지 않고 구약 · 신약 격자에서 고른다.
                          child: InkWell(
                            borderRadius: BorderRadius.circular(
                              AppRadius.control,
                            ),
                            onTap: () => _pickBook(bible),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: '책',
                                suffixIcon: Icon(AppIcons.caretDown, size: 18),
                              ),
                              child: Text(
                                bibleBooks[_book],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _Pick<int>(
                            key: ValueKey('c$_book'),
                            value: _chapter,
                            label: '장',
                            items: [
                              for (var i = 0; i < chapters; i++)
                                DropdownMenuItem(
                                  value: i,
                                  child: Text('${i + 1}장'),
                                ),
                            ],
                            onChanged: (v) => setState(() {
                              _chapter = v!;
                              _resetRange(bible);
                              _ref.clear();
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _Pick<int>(
                            key: ValueKey('f$_book/$_chapter'),
                            value: _from,
                            label: '시작 절',
                            items: [
                              for (var i = 0; i < verses.length; i++)
                                DropdownMenuItem(
                                  value: i,
                                  child: Text('${i + 1}절'),
                                ),
                            ],
                            onChanged: (v) => setState(() {
                              _from = v!;
                              if (_to < _from) _to = _from;
                            }),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            '~',
                            style: TextStyle(color: palette.muted),
                          ),
                        ),
                        Expanded(
                          child: _Pick<int>(
                            key: ValueKey('t$_book/$_chapter/$_from/$_to'),
                            value: _to,
                            label: '끝 절',
                            items: [
                              for (var i = _from; i < verses.length; i++)
                                DropdownMenuItem(
                                  value: i,
                                  child: Text('${i + 1}절'),
                                ),
                            ],
                            onChanged: (v) => setState(() => _to = v!),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (pick != null) ...[
              const SizedBox(height: 16),
              // 미리보기: 구절 이름표 아래에 절 번호가 눈에 띄는 본문.
              VersePreview(
                title: pick.title,
                body: pick.body,
                // 번역: 아이콘만 있는 테두리 버튼, 누르면 목록이 열린다.
                trailing: PopupMenuButton<BibleVersion>(
                  tooltip: '번역 · ${_version.label}',
                  position: PopupMenuPosition.under,
                  initialValue: _version,
                  onSelected: (v) => setState(() => _version = v),
                  itemBuilder: (_) => [
                    for (final v in BibleVersion.values)
                      PopupMenuItem(value: v, child: Text(v.label)),
                  ],
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: palette.surface,
                      border: Border.all(color: palette.border),
                      borderRadius: BorderRadius.circular(AppRadius.control),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(7),
                      child: Icon(AppIcons.languages, size: 18),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: pick == null
                      ? null
                      : () => Navigator.pop(context, pick),
                  child: const Text('넣기'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// 이름표가 칸 안에 뜨는 선택 상자 (좁은 칸에 나란히 놓을 때).
class _Pick<T> extends StatelessWidget {
  const _Pick({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    initialValue: value,
    isExpanded: true,
    menuMaxHeight: 320,
    borderRadius: BorderRadius.circular(AppRadius.card),
    icon: const Icon(AppIcons.caretDown, size: 18),
    decoration: InputDecoration(labelText: label),
    items: items,
    onChanged: onChanged,
  );
}

class _Message extends StatelessWidget {
  const _Message({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Text(body, style: TextStyle(color: context.palette.muted)),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ),
      ],
    );
  }
}

/// 성경 구절 미리보기: 구절 이름표 아래에 절 번호가 눈에 띄는 본문. 불러오기 창과 말씀묵상의 "읽기"가 같이 쓴다.
/// [trailing]은 이름표 오른쪽에 놓는 위젯 (예: 번역 선택).
class VersePreview extends StatelessWidget {
  const VersePreview({
    super.key,
    required this.title,
    required this.body,
    this.trailing,
    this.height = 200,
  });

  final String title;

  /// 한 줄에 한 절: "절번호 본문".
  final String body;
  final Widget? trailing;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: context.cardEdge),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: TextStyle(color: palette.ink)),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: height,
              child: SingleChildScrollView(
                child: Text.rich(
                  TextSpan(
                    children: verseSpans(
                      body,
                      palette.muted,
                      showNumbers: AppScope.read(context)
                          .preferences
                          .showVerseNumbers,
                    ),
                  ),
                  style: const TextStyle(height: 1.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 본문 "절번호 본문" 줄들을 글 조각으로: 절 번호는 맨 앞 숫자 한 덩어리일 때만 작게 강조한다
/// (번호가 없는 글의 첫 낱말은 그대로 둔다). [numberColor]는 절 번호 색이다.
List<TextSpan> verseSpans(
  String body,
  Color numberColor, {
  double numberSize = 12,
  bool showNumbers = true,
}) => [
  for (final line in body.split('\n'))
    ...() {
      final m = RegExp(r'^(\d+)\s+(.*)$').firstMatch(line);
      if (m == null) return [TextSpan(text: '$line\n')];
      if (!showNumbers) return [TextSpan(text: '${m.group(2)}\n')];
      return [
        TextSpan(
          text: '${m.group(1)} ',
          style: TextStyle(color: numberColor, fontSize: numberSize),
        ),
        TextSpan(text: '${m.group(2)}\n'),
      ];
    }(),
];

/// 성경 구절 읽기 창의 내용: 말씀묵상 상세의 말씀 카드와 같은 베이지 종이 위에 구절 이름표와 큰 본문.
/// 제목 없이 오른쪽 위의 닫기 버튼만 있다. 본문이 길면 종이 안에서 스크롤된다.
class VerseReader extends StatelessWidget {
  const VerseReader({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final paper = dark ? const Color(0xFF2B2620) : const Color(0xFFF6EFE3);
    final edge = dark ? const Color(0xFF3D362D) : const Color(0xFFE6DCCB);
    final ink = palette.ink;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.62;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 구절 이름표(왼쪽)와 닫기(오른쪽).
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: ink.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(AppIcons.bookOpen, size: 16, color: ink),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(color: ink, fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: '닫기',
              visualDensity: VisualDensity.compact,
              onPressed: () => Navigator.pop(context),
              icon: const Icon(AppIcons.x),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: paper,
              border: Border.all(color: edge),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: SelectableText.rich(
                TextSpan(
                  children: verseSpans(
                    body.trimRight(),
                    ink.withValues(alpha: 0.55),
                    numberSize: 13,
                    showNumbers: AppScope.read(context)
                        .preferences
                        .showVerseNumbers,
                  ),
                ),
                style: readingStyle(context)
                    .copyWith(color: ink, fontSize: 18, height: 1.9),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 책 고르기 격자: 구약 · 신약을 갈래별로 묶어 66권의 이름을 한눈에 늘어놓는다. 눌러 고르면 그 책 번호를 돌려준다.
class _BookGrid extends StatelessWidget {
  const _BookGrid({required this.selected});

  final int selected;

  /// (이름, 시작 책 번호, 끝 책 번호): 구약은 0~38, 신약은 39~65.
  static const _oldGroups = [
    ('율법서', 0, 4),
    ('역사서', 5, 16),
    ('시가서', 17, 21),
    ('선지서', 22, 38),
  ];
  static const _newGroups = [
    ('복음서 · 사도행전', 39, 43),
    ('바울 서신', 44, 56),
    ('일반 서신 · 계시록', 57, 65),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    Widget group(String name, int from, int to) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: TextStyle(color: palette.muted, fontSize: 12.5)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = from; i <= to; i++)
                InkWell(
                  onTap: () => Navigator.pop(context, i),
                  borderRadius: BorderRadius.circular(AppRadius.control),
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 44),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: i == selected ? palette.ink : palette.surface,
                      border: Border.all(
                        color: i == selected ? palette.ink : palette.border,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.control),
                    ),
                    child: Text(
                      bibleBooks[i],
                      style: TextStyle(
                        color: i == selected ? palette.surface : palette.ink,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('구약', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        for (final g in _oldGroups) group(g.$1, g.$2, g.$3),
        const SizedBox(height: 6),
        Text('신약', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        for (final g in _newGroups) group(g.$1, g.$2, g.$3),
      ],
    );
  }
}
