import '../../../core/widgets/app_loader.dart';

import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/icons.dart';
import '../../../core/theme.dart';
import '../../../data/bible_books.dart';
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
  const BiblePickerDialog({super.key});

  @override
  State<BiblePickerDialog> createState() => _BiblePickerDialogState();
}

class _BiblePickerDialogState extends State<BiblePickerDialog> {
  late final Future<Bible> _bible = AppScope.read(context).bible.load();

  BibleVersion _version = BibleVersion.gae;
  int _book = 0;
  int _chapter = 0;
  int _from = 0;
  int _to = 0;

  List<BibleVerse> _verses(Bible bible) => bible.verses(_book, _chapter);

  void _resetRange(Bible bible) {
    final count = _verses(bible).length;
    _from = 0;
    _to = count == 0 ? 0 : 0;
  }

  BiblePick _pick(Bible bible) {
    final verses = _verses(bible);
    final chosen = verses.sublist(_from, _to + 1);
    final first = chosen.first.verse + 1;
    final last = chosen.last.verse + 1;
    final range = first == last ? '$first' : '$first-$last';
    return BiblePick(
      // 책 이름은 줄임말로 쓴다 (예: 살후 3:1-3).
      title:
          '${bibleBookAbbreviations[_book]} ${_chapter + 1}:$range (${_version.label})',
      body: [
        for (final v in chosen) '${v.verse + 1} ${v.text(_version).trim()}',
      ].join('\n'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<Bible>(
      future: _bible,
      builder: (context, snap) {
        if (snap.hasError) {
          return _Message(
            title: '성경 본문을 불러오지 못했어요',
            body:
                '${snap.error}\n\n앱 운영자가 대시보드에서 성경 파일(verse.csv)을 올렸는지, '
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
        final verses = _verses(bible);
        final chapters = bible.chapterCount(_book);
        final palette = context.palette;
        final pick = verses.isEmpty ? null : _pick(bible);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('성경 구절 불러오기', style: theme.textTheme.titleLarge),
            const SizedBox(height: 20),
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
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _Pick<int>(
                            value: _book,
                            label: '책',
                            items: [
                              for (var i = 0; i < bibleBooks.length; i++)
                                DropdownMenuItem(
                                  value: i,
                                  child: Text(bibleBooks[i]),
                                ),
                            ],
                            onChanged: (v) => setState(() {
                              _book = v!;
                              _chapter = 0;
                              _resetRange(bible);
                            }),
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
              DecoratedBox(
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
                            child: Text(
                              pick.title,
                              style: TextStyle(
                                color: palette.ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          // 번역: 아이콘만 있는 테두리 버튼, 누르면 목록이 열린다.
                          PopupMenuButton<BibleVersion>(
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
                                borderRadius: BorderRadius.circular(
                                  AppRadius.control,
                                ),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(7),
                                child: Icon(AppIcons.languages, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 200,
                        child: SingleChildScrollView(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                for (final line in pick.body.split('\n')) ...[
                                  TextSpan(
                                    text: '${line.split(' ').first} ',
                                    style: TextStyle(
                                      color: palette.muted,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        '${line.substring(line.indexOf(' ') + 1)}\n',
                                  ),
                                ],
                              ],
                            ),
                            style: const TextStyle(height: 1.8),
                          ),
                        ),
                      ),
                    ],
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
