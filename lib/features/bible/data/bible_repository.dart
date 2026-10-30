import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../../core/app_exception.dart';

/// 성경 번역. [column]은 `verse.csv`의 열 이름이다.
enum BibleVersion {
  gae('gae', '개역개정'),
  han('han', '개역한글'),
  sae('sae', '새번역'),
  kjv('kjv', 'KJV'),
  niv('niv', 'NIV');

  const BibleVersion(this.column, this.label);

  final String column;
  final String label;
}

/// 한 절. 번역별 본문은 [BibleVersion.index] 순서로 들어 있다.
class BibleVerse {
  const BibleVerse(this.book, this.chapter, this.verse, this.texts);

  /// 모두 0부터 시작한다 (책 0 = 창세기, 장 0 = 1장, 절 0 = 1절).
  final int book;
  final int chapter;
  final int verse;
  final List<String> texts;

  String text(BibleVersion v) => texts[v.index];
}

/// 읽어 온 성경 전체. 책·장으로 절을 찾는다.
class Bible {
  Bible._(this._byChapter);

  final Map<int, Map<int, List<BibleVerse>>> _byChapter;

  /// 책의 장 수.
  int chapterCount(int book) => _byChapter[book]?.length ?? 0;

  /// 한 장의 절들 (절 순서).
  List<BibleVerse> verses(int book, int chapter) =>
      _byChapter[book]?[chapter] ?? const [];
}

/// 성경 본문(`bible/verse.csv`, Firebase Storage)을 올리고 읽는다.
/// 파일은 앱 운영자가 한 번 올려 두고, 말씀묵상을 쓸 때 구절을 골라 가져온다.
class BibleRepository {
  BibleRepository(this._storage);

  final FirebaseStorage _storage;

  /// 파일 위치. `storage.rules`의 bible 경로와 같아야 한다.
  static const path = 'bible/verse.csv';

  static const _maxBytes = 60 * 1024 * 1024;

  Future<Bible>? _loaded;

  /// 올린 성경 파일이 있는가.
  Future<bool> exists() async {
    try {
      await _storage.ref(path).getMetadata();
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') return false;
      rethrow;
    }
  }

  /// `verse.csv`를 올린다. 머리글과 내용을 확인해서 잘못된 파일이면 올리지 않는다.
  Future<void> upload(Uint8List bytes) async {
    // 올리기 전에 읽어 본다 (형식이 틀리면 예외).
    parse(bytes);
    await _storage
        .ref(path)
        .putData(bytes, SettableMetadata(contentType: 'text/csv'));
    _loaded = null;
  }

  /// 성경 전체. 처음 한 번만 내려받아 읽고 이후에는 메모리에 둔 것을 쓴다.
  /// 실패하면 다음에 다시 시도할 수 있게 기억하지 않는다.
  Future<Bible> load() => _loaded ??= _download().catchError((Object e) {
    _loaded = null;
    throw e;
  });

  /// 앱에 담겨 있는 기본 성경.
  static const _assetPath = 'assets/bible/bible_verses.csv';

  /// Storage에 올라갈 수 있는 파일 이름 (앱이 올리는 이름, 원본 이름 그대로 올린 경우).
  static const _remotePaths = [path, 'bible/bible_verses.csv'];

  /// 기본은 앱에 담긴 파일이다. Storage에 올라간 파일의 크기가 다르면 그 내용으로 바꿔 읽는다.
  /// Storage를 읽지 못해도(오프라인 등) 기본 성경으로 보여 준다.
  Future<Bible> _download() async {
    final bundled = (await rootBundle.load(_assetPath)).buffer.asUint8List();
    final remote = await _newerRemote(bundled.length);
    return parse(remote ?? bundled);
  }

  Future<Uint8List?> _newerRemote(int bundledSize) async {
    for (final p in _remotePaths) {
      try {
        final meta = await _storage.ref(p).getMetadata();
        if (meta.size == bundledSize) return null;
        return await _storage.ref(p).getData(_maxBytes);
      } on FirebaseException catch (e) {
        if (e.code == 'object-not-found') continue;
        return null;
      }
    }
    return null;
  }

  /// CSV 내용을 읽어 [Bible]로 만든다. 형식이 틀리면 [AppException].
  static Bible parse(Uint8List bytes) {
    final text = utf8.decode(bytes, allowMalformed: true);
    final rows = _csvRows(text);
    if (rows.isEmpty) throw const AppException('성경 파일이 비어 있어요.');
    final header = rows.first;
    // id,page,book,chapter,verse,han,gae,sae,kjv,niv
    final cols = {for (var i = 0; i < header.length; i++) header[i].trim(): i};
    for (final key in ['book', 'chapter', 'verse']) {
      if (!cols.containsKey(key)) {
        throw AppException('성경 파일 형식이 달라요. "$key" 열이 없어요.');
      }
    }
    for (final v in BibleVersion.values) {
      if (!cols.containsKey(v.column)) {
        throw AppException('성경 파일 형식이 달라요. "${v.column}" 열이 없어요.');
      }
    }
    final byChapter = <int, Map<int, List<BibleVerse>>>{};
    for (var r = 1; r < rows.length; r++) {
      final row = rows[r];
      if (row.length < header.length) continue;
      final book = int.tryParse(row[cols['book']!]);
      final chapter = int.tryParse(row[cols['chapter']!]);
      final verse = int.tryParse(row[cols['verse']!]);
      if (book == null || chapter == null || verse == null) continue;
      final verseData = BibleVerse(book, chapter, verse, [
        for (final v in BibleVersion.values) row[cols[v.column]!],
      ]);
      byChapter
          .putIfAbsent(book, () => {})
          .putIfAbsent(chapter, () => [])
          .add(verseData);
    }
    if (byChapter.isEmpty) throw const AppException('성경 파일에서 구절을 찾지 못했어요.');
    for (final chapters in byChapter.values) {
      for (final list in chapters.values) {
        list.sort((a, b) => a.verse.compareTo(b.verse));
      }
    }
    return Bible._(byChapter);
  }

  /// 따옴표 안의 쉼표·줄바꿈·겹따옴표("")를 처리하는 CSV 읽기.
  static List<List<String>> _csvRows(String text) {
    final rows = <List<String>>[];
    var row = <String>[];
    final cell = StringBuffer();
    var quoted = false;
    final n = text.length;
    for (var i = 0; i < n; i++) {
      final c = text.codeUnitAt(i);
      if (quoted) {
        if (c == 0x22) {
          if (i + 1 < n && text.codeUnitAt(i + 1) == 0x22) {
            cell.writeCharCode(0x22);
            i++;
          } else {
            quoted = false;
          }
        } else {
          cell.writeCharCode(c);
        }
      } else if (c == 0x22) {
        quoted = true;
      } else if (c == 0x2C) {
        row.add(cell.toString());
        cell.clear();
      } else if (c == 0x0A || c == 0x0D) {
        if (c == 0x0D && i + 1 < n && text.codeUnitAt(i + 1) == 0x0A) i++;
        row.add(cell.toString());
        cell.clear();
        if (row.length > 1 || row.first.isNotEmpty) rows.add(row);
        row = <String>[];
      } else {
        cell.writeCharCode(c);
      }
    }
    if (cell.isNotEmpty || row.isNotEmpty) {
      row.add(cell.toString());
      rows.add(row);
    }
    return rows;
  }
}
