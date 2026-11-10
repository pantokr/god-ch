import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// God-Ch 마크 (God's Church): G 글자의 가로획이 십자가가 된다.
/// 도형은 `tool/make_icons.py`의 앱 아이콘과 같은 좌표(0~100)를 쓴다.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 48, this.color = Colors.white});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _MarkPainter(color));
}

/// 앱 로고: 강조색 바탕의 둥근 타일 위에 [BrandMark]. 앱 아이콘 · 스플래시 · 로그인 · 왼쪽 메뉴 · 앱 정보가 모두 이것을 쓴다.
/// 타일의 모서리와 마크 크기는 [size]에 비례한다. [glow]면 타일 아래에 은은한 빛이 번진다.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 64, this.glow = false});

  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppDepth.brand(context),
        borderRadius: BorderRadius.circular(size * 0.25),
        boxShadow: glow ? AppDepth.glow(context) : null,
      ),
      alignment: Alignment.center,
      child: BrandMark(size: size * 0.625, color: palette.onBrand),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.color);

  final Color color;

  static const _r = 26.0, _w = 9.0, _arm = 8.0, _barY = 47.0;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = _w * u
      ..isAntiAlias = true;
    // G 고리: 가로획 높이에서 시계 방향으로 돌아 오른쪽 위에서 끝난다.
    final start = math.asin((_barY - 50) / _r);
    const stop = -48 * math.pi / 180;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(50 * u, 50 * u), radius: _r * u),
      start,
      (2 * math.pi) - (start - stop),
      false,
      paint,
    );
    // 십자가: 세로획과 G의 가로획을 겸하는 가로획.
    paint.strokeWidth = _arm * u;
    canvas.drawLine(Offset(50 * u, 37 * u), Offset(50 * u, 61 * u), paint);
    canvas.drawLine(
      Offset(43 * u, _barY * u),
      Offset((50 + _r + _w / 2 - 4) * u, _barY * u),
      paint,
    );
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.color != color;
}
