import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/preferences_controller.dart';
import '../../../core/icons.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/expandable_text.dart';
import '../../../data/bible_reference.dart';

/// 개인 설정의 말씀묵상 카드 색 (고르지 않았으면 null).
/// 말씀 · 묵상 · 넘김 막대 · 작성 정보 · 내 묵상 카드가 모두 이 색을 쓴다.
Color? bibleTint(BuildContext context) =>
    AppScope.read(context).preferences
        .tintOf('bible')
        .colorFor(Theme.of(context).brightness);

/// 성경 본문 카드. 개인 설정의 "디자인"([DevotionDesign])을 따른다:
/// - 종이: 베이지 종이 바탕에 큰 인용 부호와 구절 이름표.
/// - 심플: 일반 카드에 구절 이름과 본문.
/// - 인용: 왼쪽에 굵은 선이 있는 인용 글.
/// 절 번호 표시 · 책 이름 표기(전체 · 약어)도 개인 설정이 그대로 반영된다.
class VerseCard extends StatelessWidget {
  const VerseCard({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final prefs = AppScope.read(context).preferences;
    final text = displayVerseBody(body, prefs.showVerseNumbers);
    return switch (prefs.devotionDesign) {
      DevotionDesign.paper => _PaperVerse(title: title, text: text),
      DevotionDesign.simple => _SimpleVerse(title: title, text: text),
      DevotionDesign.quote => _QuoteVerse(title: title, text: text),
    };
  }
}

/// 본문 글(앱에서 유일하게 명조): 긴 본문은 앞부분만 보이고 "더보기"로 펼친다.
Widget _body(BuildContext context, String text, Color color, {double? size}) =>
    ExpandableText(
      text,
      maxLines: 12,
      onDark: true,
      style: verseTextStyle(context).copyWith(
        color: color,
        fontSize: size ?? 19,
        height: 1.9,
        fontWeight: FontWeight.w500,
      ),
    );

class _PaperVerse extends StatelessWidget {
  const _PaperVerse({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;
    // 베이지 바탕 (다크에서는 어두운 베이지). 글자는 본문 글자색을 쓴다.
    final paper = dark ? const Color(0xFF2B2620) : const Color(0xFFF6EFE3);
    final edge = dark ? const Color(0xFF3D362D) : const Color(0xFFE6DCCB);
    final tint = bibleTint(context);
    final onColor = palette.ink;
    return DecoratedBox(
      decoration: BoxDecoration(
        // 개인 설정: 말씀묵상 카드 색. 정하지 않으면 베이지 종이 색이다.
        color: tint ?? paper,
        borderRadius: BorderRadius.zero,
        // 색을 골랐으면 테두리 · 그림자도 베이지가 아니라 중립색이다.
        border: Border.all(color: tint == null ? edge : context.cardEdge),
        boxShadow: [
          BoxShadow(
            color:
                (dark || tint != null ? Colors.black : const Color(0xFF6B5A3E))
                    .withValues(alpha: dark ? 0.4 : 0.18),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.zero,
        child: Stack(
          children: [
            // 큰 인용 부호 장식.
            Positioned(
              right: 12,
              top: -18,
              child: Text(
                '”',
                style: TextStyle(
                  fontSize: 160,
                  height: 1,
                  fontWeight: FontWeight.w600,
                  color: onColor.withValues(alpha: 0.13),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: onColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: onColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(AppIcons.bookOpen, size: 16, color: onColor),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: onColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _body(context, text, onColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 심플: 일반 카드. 위에 구절 이름을 작게, 아래에 본문.
class _SimpleVerse extends StatelessWidget {
  const _SimpleVerse({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Card(
      shape: context.edgedCardShape,
      color: bibleTint(context),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(AppIcons.bookOpen, size: 16, color: palette.accent),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: palette.accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _body(context, text, palette.ink, size: 17),
          ],
        ),
      ),
    );
  }
}

/// 인용: 왼쪽 굵은 선, 구절 이름은 본문 아래 오른쪽에 작게.
class _QuoteVerse extends StatelessWidget {
  const _QuoteVerse({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bibleTint(context) ?? Colors.transparent,
        border: Border(left: BorderSide(color: palette.accent, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _body(context, text, palette.ink, size: 18),
            const SizedBox(height: 10),
            Text(
              '— $title',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: palette.muted,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
