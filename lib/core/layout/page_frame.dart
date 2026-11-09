import 'package:flutter/material.dart';

import '../theme.dart';
import 'responsive.dart';

/// [PageFrame] 안쪽 내용이 화면(페이지 영역) 좌우 끝까지 퍼지려면 양쪽으로 얼마나 더 나가야 하는지를 알려 준다.
/// 정렬 줄처럼 화면 너비를 꽉 채우는 부분이 읽는다.
class PageBleed extends InheritedWidget {
  const PageBleed({super.key, required this.extra, required super.child});

  /// 내용 영역 한쪽 끝에서 화면 끝까지의 거리 (바깥 여백 + 최대 폭 밖의 남는 폭의 절반).
  final double extra;

  static PageBleed? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PageBleed>();

  @override
  bool updateShouldNotify(PageBleed old) => old.extra != extra;
}

/// 가운데 정렬된 최대 폭 콘텐츠 영역.
class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.child,
    this.maxWidth = kContentWidth,
    this.verticalPadding = 28,
    this.header,
    this.inset = false,
  });

  /// 내용 위에 함께 스크롤되는 머리 (예: 제목과 스위치). 없으면 [child]만 그린다.
  final Widget? header;

  /// true이면 폼처럼 내용 전체가 좌우 여백 안에 놓인다 (입력칸 · 버튼이 화면 끝에 닿지 않는다).
  /// 기본(false)은 상자는 화면 너비를 채우고 글자만 여백을 둔다.
  final bool inset;

  final Widget child;
  final double maxWidth;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    // 좁은 화면에서는 좌우 여백이 없다: 상자는 화면 너비를 채우고 글자만 [Gutter]로 여백을 둔다.
    final pad = MediaQuery.sizeOf(context).width < kNarrow && !inset
        ? 0.0
        : pagePadding(context);
    return LayoutBuilder(
      builder: (context, box) {
        final full = box.maxWidth;
        final frame = full < maxWidth ? full : maxWidth;
        final frameChild = _frame(context, pad);
        return PageBleed(
          extra: (full - frame) / 2 + pad,
          child: inset ? InsetScope(child: frameChild) : frameChild,
        );
      },
    );
  }

  Widget _frame(BuildContext context, double pad) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          // 아래에는 떠 있는 하단 탭이 가린 높이(MediaQuery 아래 여백)를 더한다.
          padding: EdgeInsets.fromLTRB(
            pad,
            verticalPadding,
            pad,
            verticalPadding + MediaQuery.paddingOf(context).bottom,
          ),
          child: header == null
              ? child
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [header!, child],
                ),
        ),
      ),
    );
  }
}

/// 본문 위에 놓는 페이지 제목 줄. 오른쪽에 주요 버튼을 둘 수 있고, 제목 아래에 2~3줄 설명([description])을 둘 수 있다.
class PageTitle extends StatelessWidget {
  const PageTitle({
    super.key,
    required this.title,
    this.description,
    this.action,
    this.gap = 20,
  });

  /// 비어 있으면 제목 줄을 그리지 않는다 (제목이 위쪽 바에 있는 탭).
  final String title;

  /// 제목 아래의 탭 설명. 가로 너비를 다 쓰지 않고 [descriptionWidth]까지만 펴지며 3줄을 넘으면 줄인다.
  final String? description;
  final Widget? action;

  /// 제목(과 설명) 아래 간격. 검색 · 정렬 패널이 바로 아래에 오는 탭은 [panelGap]을 쓴다.
  final double gap;

  static const descriptionWidth = 440.0;

  /// 탭 제목 · 설명과 검색 조건 패널 사이의 간격.
  static const panelGap = 40.0;

  /// 제목 글자 모양 (높이 계산과 그리기가 같은 것을 쓴다).
  static TextStyle? _titleStyle(BuildContext context) =>
      Theme.of(context).textTheme.headlineSmall
          ?.copyWith(fontWeight: FontWeight.w600);

  /// 설명 글자 모양.
  static TextStyle? _descriptionStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium
          ?.copyWith(color: context.palette.muted, height: 1.55);

  /// 설명이 있을 때 제목 한 줄 + 설명 3줄이 실제로 차지하는 높이. 같은 글자 모양으로 직접 재서 구하므로
  /// 글꼴 · 글자 크기 설정이 달라도 어긋나 넘치지 않는다. 설명이 한 줄이든 세 줄이든 높이가 같아서
  /// 중보기도 · 일정 · 말씀묵상의 패널이 같은 자리에서 시작한다.
  static double fixedHeight(BuildContext context, {bool withTitle = true}) {
    double measure(TextStyle? style, String text, int lines) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: lines,
      )..layout(maxWidth: double.infinity);
      final h = painter.height;
      painter.dispose();
      return h;
    }

    final title = measure(_titleStyle(context), '가', 1);
    // 줄바꿈 문자를 직접 쓰지 않고 세 줄짜리 글을 만든다.
    final threeLines = List.filled(3, '가').join(String.fromCharCode(10));
    final desc = measure(_descriptionStyle(context), threeLines, 3);
    // 줄 높이의 반올림 오차와 글꼴이 바뀔 때의 줄 높이 차이에 대비해 넉넉히 더 둔다.
    return withTitle ? title + 8 + desc + 12 : desc + 12;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: textGutter(context),
        right: textGutter(context),
        bottom: gap,
      ),
      child: SizedBox(
        height: description == null
            ? null
            : fixedHeight(context, withTitle: title.isNotEmpty),
        child: Row(
          crossAxisAlignment: description == null
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title.isNotEmpty)
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (description != null) ...[
                    if (title.isNotEmpty) const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: descriptionWidth,
                      ),
                      child: Text(
                        // 온점 뒤에서만 줄을 바꾼다 (쉼표가 있는 문장은 한 줄로 이어진다).
                        description!
                            .replaceAllMapped(
                              RegExp(r'\.\s*'),
                              (m) => '.${String.fromCharCode(10)}',
                            )
                            .trim(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: context.palette.muted,
                          height: 1.55,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (action != null) ...[const SizedBox(width: 12), ?action],
          ],
        ),
      ),
    );
  }
}
