import '../icons.dart';

import 'package:flutter/material.dart';

import '../theme.dart';

/// 목록 줄 가장자리에 세로로 놓는 숫자 표시: 조회수 · 좋아요 (선택: 참여 인원).
/// [liked]이면 하트가 채워진다. 숫자는 천 단위로 줄여 보인다.
class StatIcons extends StatelessWidget {
  const StatIcons({
    super.key,
    required this.views,
    required this.likes,
    this.liked = false,
    this.color,
    this.showViews = true,
    this.horizontal = false,
  });

  /// 조회수를 보여 주는가 (교회 설정). 끄면 좋아요만 나온다.
  final bool showViews;

  /// true이면 위아래가 아니라 좌우로 놓는다: 좋아요(하트)가 왼쪽, 조회수가 오른쪽.
  final bool horizontal;

  final int views;
  final int likes;
  final bool liked;

  /// 글자 · 아이콘 색. 없으면 보조 글자색.
  final Color? color;

  static String compact(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(n >= 10000 ? 0 : 1)}k' : '$n';

  @override
  Widget build(BuildContext context) {
    final muted = color ?? context.palette.muted;
    Widget item(IconData icon, int n, {Color? tint}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: tint ?? muted),
        const SizedBox(width: 4),
        Text(
          compact(n),
          style: TextStyle(
            color: tint ?? muted,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
    final heart = item(
      liked ? AppIcons.heartFill : AppIcons.heart,
      likes,
      tint: liked ? const Color(0xFFE5484D) : null,
    );
    if (horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          heart,
          if (showViews) ...[
            const SizedBox(width: 12),
            item(AppIcons.eyeCount, views),
          ],
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (showViews) ...[
          item(AppIcons.eyeCount, views),
          const SizedBox(height: 8),
        ],
        item(
          liked ? AppIcons.heartFill : AppIcons.heart,
          likes,
          tint: liked ? const Color(0xFFE5484D) : null,
        ),
      ],
    );
  }
}

/// 알록달록 목록에서 항목마다 돌려 쓰는 파스텔 색. 라이트 · 다크에서 모두 글자가 읽히도록 면 위에 옅게 깐다.
class Pastel {
  Pastel._();

  static const _hues = [
    Color(0xFF7C83FD), // 인디고
    Color(0xFFFF8A80), // 코랄
    Color(0xFF4DB6AC), // 민트
    Color(0xFFFFB74D), // 살구
    Color(0xFFBA68C8), // 라벤더
    Color(0xFF64B5F6), // 하늘
  ];

  /// 항목 [i]의 포인트 색.
  static Color hue(int i) => _hues[i.abs() % _hues.length];

  /// 항목 [i]의 카드 면 (포인트 색을 옅게 섞은 색).
  static Color fill(BuildContext context, int i) => Color.alphaBlend(
    hue(i).withValues(
      alpha: Theme.of(context).brightness == Brightness.dark ? 0.20 : 0.16,
    ),
    context.palette.surface,
  );

  /// 글자 [text]로 고른 색 번호 (같은 글은 늘 같은 색).
  static int indexOf(String text) =>
      text.codeUnits.fold(0, (a, b) => (a * 31 + b) & 0x7fffffff) %
      _hues.length;
}
