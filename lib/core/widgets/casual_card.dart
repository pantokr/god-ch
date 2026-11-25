import 'package:flutter/material.dart';

import '../layout/responsive.dart';
import '../theme.dart';
import 'stat_icons.dart' show Pastel;

/// 중보기도 · 말씀묵상 목록이 함께 쓰는 캐주얼 카드. 내용(본문)은 싣지 않고 누가 · 무엇 · 얼마나만 보인다.
/// - 리스트: 카드를 좌우로 나눈다. 왼쪽은 아바타 영역(오른쪽과 같은 바탕색에 큰 사진, 이름 알약이 사진 아래에 걸친다, 우리 소속과 같은 모양)이고,
///   오른쪽은 [title] · 날짜 · [stats]. 신규 글이면 아바타 영역 왼쪽 위에 NEW 알약.
/// - 격자: 반 너비 카드라서 위 아래로 쌓는다. 사진과 이름 줄 아래에 [title], 맨 아래에 [date]와 [stats].
/// - 카드마다 [hueSeed]로 정해진 파스텔 색 한 가지가 아바타 영역 바탕 · 사진 테두리 · 얇은 선에 쓰인다 (그라데이션은 쓰지 않는다).
class CasualCard extends StatelessWidget {
  const CasualCard({
    super.key,
    required this.hueSeed,
    required this.leading,
    required this.name,
    required this.title,
    required this.stats,
    required this.onTap,
    this.date = '',
    this.fresh = false,
    this.grid = false,
    this.fill,
    this.gutter,
  });

  /// 파스텔 색을 고르는 글자 (보통 글 아이디). 같은 글은 늘 같은 색이다.
  final String hueSeed;

  /// 사진 · 아이콘을 안쪽 지름에 맞춰 만든다. 바깥에 파스텔 그라데이션 테두리가 둘러진다.
  final Widget Function(double diameter) leading;

  /// 글쓴이 이름. 리스트에서는 사진에 걸친 알약, 격자에서는 사진 옆 글자다. 비어 있으면 보이지 않는다.
  final String name;

  /// 글의 제목 (중보기도 제목 · 말씀 구절). 줄 수와 글자 모양은 쓰는 쪽이 정한다.
  final Widget title;

  /// 올린 시각 글자 (`fmtPosted`). 비어 있으면 보이지 않는다.
  final String date;
  final Widget stats;
  final VoidCallback onTap;
  final bool fresh;
  final bool grid;

  /// 카드 바탕색 (개인 설정의 카드 색). 없으면 면색이다.
  final Color? fill;

  /// 카드 좌우 바깥 여백. 없으면 글 여백(`textGutter`)이고, 격자에서는 0을 준다.
  final double? gutter;

  /// 테두리를 포함한 사진 지름.
  double get _ring => grid ? 48 : 64;

  /// 리스트 왼쪽 아바타 영역의 너비.
  static const _panelWidth = 96.0;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final i = Pastel.indexOf(hueSeed);
    final hue = Pastel.hue(i);
    final radius = BorderRadius.circular(AppRadius.card);
    final side = gutter ?? textGutter(context);

    final avatar = Container(
      width: _ring,
      height: _ring,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // 그라데이션 없이 한 가지 파스텔 색 테두리.
        color: hue,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: palette.surface,
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: ClipOval(child: leading(_ring - 9)),
        ),
      ),
    );

    final newPill = fresh
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.like,
              borderRadius: BorderRadius.circular(99),
            ),
            child: const Text(
              'NEW',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          )
        : null;

    final dateText = date.isEmpty
        ? null
        : Text(
            date,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: palette.muted, fontSize: 12.5),
          );

    final divider = Divider(
      height: 1,
      color: hue.withValues(alpha: dark ? 0.3 : 0.22),
    );

    // 리스트 왼쪽 아바타 영역: 큰 사진에 이름 알약이 아래쪽에 걸친다.
    final panel = Container(
      width: _panelWidth,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 18),
      alignment: Alignment.center,
      child: SizedBox(
        height: _ring + (name.isEmpty ? 0 : 12),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            avatar,
            if (name.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: hue.withValues(alpha: 0.6)),
                      boxShadow: AppShadow.soft(context),
                    ),
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: palette.ink, fontSize: 12.5),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    final footer = Row(
      children: [
        Expanded(child: dateText ?? const SizedBox.shrink()),
        const SizedBox(width: 8),
        Flexible(
          flex: 0,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: stats,
          ),
        ),
      ],
    );

    final Widget body;
    if (grid) {
      body = Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                avatar,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (name.isNotEmpty)
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: palette.muted, fontSize: 14),
                        ),
                      // 반 너비 카드는 이름 줄이 좁아서 NEW 알약이 이름 아래로 내려온다.
                      if (newPill != null) ...[
                        if (name.isNotEmpty) const SizedBox(height: 4),
                        newPill,
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            title,
            const Spacer(),
            const SizedBox(height: 16),
            divider,
            const SizedBox(height: 12),
            if (dateText != null) ...[dateText, const SizedBox(height: 10)],
            Align(
              alignment: Alignment.centerRight,
              child: FittedBox(fit: BoxFit.scaleDown, child: stats),
            ),
          ],
        ),
      );
    } else {
      body = ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card - 1),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 리스트에서는 NEW 알약을 아바타 영역 왼쪽 위에 둬서 제목 폭을 줄이지 않는다.
              Stack(
                children: [
                  panel,
                  if (newPill != null)
                    Positioned(top: 8, left: 8, child: newPill),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      title,
                      const SizedBox(height: 14),
                      divider,
                      const SizedBox(height: 10),
                      footer,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(side, 0, side, 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: AppShadow.soft(context),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Ink(
            decoration: BoxDecoration(
              color: fill ?? palette.surface,
              borderRadius: radius,
              border: Border.all(color: palette.border),
            ),
            child: body,
          ),
        ),
      ),
    );
  }
}
