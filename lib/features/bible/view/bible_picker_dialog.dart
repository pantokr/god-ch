import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/theme.dart';
import '../../../data/bible_books.dart';
import '../data/bible_repository.dart';
import '../../../core/widgets/app_inputs.dart';

/// 고른 구절: 제목(예: 요한복음 3:16-18 (개역개정))과 절 번호가 붙은 본문.
class BiblePick {
  const BiblePick({required this.title, required this.body});

  final String title;
  final String body;
}

/// 말씀 묵상에 넣을 성경 구절을 고른다: 번역 · 책 · 장 · 시작 절 · 끝 절.
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
      title: '${bibleBooks[_book]} ${_chapter + 1}:$range (${_version.label})',
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
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('성경 본문을 불러오는 중이에요. 처음에는 조금 걸려요.'),
              ],
            ),
          );
        }
        final bible = snap.data!;
        final verses = _verses(bible);
        final chapters = bible.chapterCount(_book);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('성경 구절 불러오기', style: theme.textTheme.titleLarge),
            AppField.spacer,
            AppDropdown<BibleVersion>(
              value: _version,
              label: '번역',
              items: [
                for (final v in BibleVersion.values)
                  DropdownMenuItem(value: v, child: Text(v.label)),
              ],
              onChanged: (v) => setState(() => _version = v!),
            ),
            AppField.spacer,
            AppDropdown<int>(
              value: _book,
              label: '책',
              items: [
                for (var i = 0; i < bibleBooks.length; i++)
                  DropdownMenuItem(value: i, child: Text(bibleBooks[i])),
              ],
              onChanged: (v) => setState(() {
                _book = v!;
                _chapter = 0;
                _resetRange(bible);
              }),
            ),
            AppField.spacer,
            Row(
              children: [
                Expanded(
                  child: AppDropdown<int>(
                    key: ValueKey('c$_book'),
                    value: _chapter,
                    label: '장',
                    items: [
                      for (var i = 0; i < chapters; i++)
                        DropdownMenuItem(value: i, child: Text('${i + 1}장')),
                    ],
                    onChanged: (v) => setState(() {
                      _chapter = v!;
                      _resetRange(bible);
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppDropdown<int>(
                    key: ValueKey('f$_book/$_chapter'),
                    value: _from,
                    label: '시작 절',
                    items: [
                      for (var i = 0; i < verses.length; i++)
                        DropdownMenuItem(value: i, child: Text('${i + 1}절')),
                    ],
                    onChanged: (v) => setState(() {
                      _from = v!;
                      if (_to < _from) _to = _from;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppDropdown<int>(
                    key: ValueKey('t$_book/$_chapter/$_from/$_to'),
                    value: _to,
                    label: '끝 절',
                    items: [
                      for (var i = _from; i < verses.length; i++)
                        DropdownMenuItem(value: i, child: Text('${i + 1}절')),
                    ],
                    onChanged: (v) => setState(() => _to = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (verses.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: context.palette.border),
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _pick(bible).body,
                    style: const TextStyle(height: 1.6),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: verses.isEmpty
                      ? null
                      : () => Navigator.pop(context, _pick(bible)),
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
