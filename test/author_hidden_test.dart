import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:god_ch/core/theme.dart';
import 'package:god_ch/core/widgets/choice_row.dart';
import 'package:god_ch/data/models/church_content.dart';
import 'package:god_ch/data/models/devotion_settings.dart';
import 'package:god_ch/data/models/prayer.dart';
import 'package:god_ch/data/models/prayer_settings.dart';
import 'package:god_ch/features/bible/view_model/devotions_view_model.dart';

Prayer _prayer({bool hidden = false, String author = 'a'}) => Prayer(
  id: 'p',
  authorId: author,
  authorName: '김성도',
  content: '기도',
  visibility: PrayerVisibility.public,
  deleted: false,
  authorHidden: hidden,
);

ChurchContent _content({bool hidden = false, String author = 'a'}) =>
    ChurchContent(
      id: 'c',
      kind: ContentKind.devotion,
      title: '요 3:16',
      body: '말씀',
      date: DateTime(2026, 11, 1),
      authorId: author,
      authorName: '김성도',
      authorHidden: hidden,
    );

void main() {
  group('작성자 비공개: 중보기도', () {
    test('공개한 글은 누구에게나 이름이 보인다', () {
      final p = _prayer();
      expect(p.hidesAuthorFrom('other', staff: false), isFalse);
      expect(p.authorLabel('other', staff: false), '김성도');
    });

    test('비공개 글은 다른 교인에게 익명이고, 본인과 교역자는 이름 뒤에 (비공개)가 붙는다', () {
      final p = _prayer(hidden: true);
      expect(p.hidesAuthorFrom('other', staff: false), isTrue);
      expect(p.authorLabel('other', staff: false), '익명');
      expect(p.hidesAuthorFrom('a', staff: false), isFalse);
      expect(p.authorLabel('a', staff: false), '김성도 (비공개)');
      expect(p.hidesAuthorFrom('staff', staff: true), isFalse);
      expect(p.authorLabel('staff', staff: true), '김성도 (비공개)');
    });
  });

  group('작성자 비공개: 말씀묵상', () {
    test('다른 교인에게는 가려지고 본인과 교역자에게는 보인다', () {
      final c = _content(hidden: true);
      expect(c.hidesAuthorFrom('other', staff: false), isTrue);
      expect(c.hidesAuthorFrom('a', staff: false), isFalse);
      expect(c.hidesAuthorFrom('x', staff: true), isFalse);
      expect(c.authorLabel('other', staff: false), '익명');
    });

    test('가려진 글쓴이 이름으로는 검색되지 않는다 (본인과 교역자는 된다)', () {
      final all = [_content(hidden: true)];
      List<ChurchContent> search(String viewer, bool staff) =>
          DevotionsViewModel.filter(
            all,
            query: '김성도',
            viewerId: viewer,
            viewerIsStaff: staff,
          );
      expect(search('other', false), isEmpty);
      expect(search('a', false), hasLength(1));
      expect(search('x', true), hasLength(1));
    });
  });

  group('작성자 비공개 허용 설정', () {
    test('기본은 허용하지 않는다', () {
      expect(PrayerSettings.standard.allowAnonymous, isFalse);
      expect(DevotionSettings.standard.allowAnonymous, isFalse);
    });

    test('저장 값에 들어 있고 복사할 수 있다', () {
      final p = PrayerSettings.standard.copyWith(allowAnonymous: true);
      expect(p.toMap()['allowAnonymous'], isTrue);
      expect(p == PrayerSettings.standard, isFalse);
      final d = DevotionSettings.standard.copyWith(allowAnonymous: true);
      expect(d.toMap()['allowAnonymous'], isTrue);
      expect(d == DevotionSettings.standard, isFalse);
    });
  });

  group('firestore.rules', () {
    final rules = File('firestore.rules').readAsStringSync();

    test('설정 문서와 글 문서가 authorHidden · allowAnonymous를 허용한다', () {
      expect(rules, contains("'allowAnonymous'"));
      expect(rules, contains("'authorHidden'"));
      expect(
        "prayerOpt(churchId, 'allowAnonymous', false)".allMatches(rules).length,
        2,
      );
      expect(
        "devotionFlag(churchId, 'allowAnonymous', false)"
            .allMatches(rules)
            .length,
        2,
      );
    });
  });

  testWidgets('글 공개 여부의 "교역자 전용"이 잘리지 않고 다 보인다', (tester) async {
    Future<void> pump(double width) => tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Scaffold(
          body: SizedBox(
            width: width,
            child: ChoiceRow<bool>(
              label: '글 공개 여부',
              roomy: true,
              options: const [
                ChoiceOption(false, '공개'),
                ChoiceOption(true, '교역자 전용'),
              ],
              value: false,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    for (final width in [360.0, 420.0, 600.0]) {
      await pump(width);
      expect(tester.takeException(), isNull, reason: '너비 $width');
      final paragraph = tester.renderObject<RenderParagraph>(
        find.text('교역자 전용'),
      );
      expect(paragraph.didExceedMaxLines, isFalse, reason: '너비 $width');
      // 한 줄로 다 들어가거나, 두 줄로 줄바꿈되어도 "…"로 잘리지 않는다.
      expect(
        paragraph.size.width,
        greaterThanOrEqualTo(70),
        reason: '너비 $width',
      );
    }
  });
}
