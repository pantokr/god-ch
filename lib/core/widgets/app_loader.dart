import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// 이 앱의 로딩 표시 "모이는 점": 흩어져 있던 점들이 가운데로 모였다가 다시 퍼지며 천천히 돈다.
/// '같이' 모인다는 앱의 뜻을 닮은 움직임이다. 점마다 앱의 강조색에서 포인트색으로 색이 이어진다.
///
/// 놓인 자리의 크기에 맞춰 그려진다 (자리가 정해지지 않으면 [defaultSize]).
/// [color]를 주면 점이 모두 그 색이다 (색 있는 버튼 위의 작은 로딩 등).
/// 시스템에서 애니메이션을 끄면 움직이지 않고 흩어진 모양으로 멈춘다.
class AppLoader extends StatefulWidget {
  const AppLoader({super.key, this.color});

  /// 점 색을 하나로 정한다. 없으면 강조색 → 포인트색 그라데이션이다.
  final Color? color;

  static const defaultSize = 40.0;

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return LayoutBuilder(
      builder: (context, box) {
        final side = [box.maxWidth, box.maxHeight]
            .where((v) => v.isFinite)
            .fold<double>(AppLoader.defaultSize, math.min);
        return Semantics(
          label: '불러오는 중',
          child: SizedBox.square(
            dimension: side,
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) => CustomPaint(
                  painter: _GatherPainter(
                    t: _c.value,
                    from: widget.color ?? palette.brand,
                    to: widget.color ?? palette.accent,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GatherPainter extends CustomPainter {
  _GatherPainter({required this.t, required this.from, required this.to});

  final double t;
  final Color from;
  final Color to;

  static const _dots = 7;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = size.shortestSide / 2;
    final base = size.shortestSide * 0.085;
    for (var i = 0; i < _dots; i++) {
      // 점마다 조금씩 늦게 모이고 퍼져서 물결처럼 이어진다.
      final p = (t - i * 0.045) % 1.0;
      // 0(모임) ↔ 1(퍼짐): 부드럽게 오가는 값.
      final spread = 0.5 - 0.5 * math.cos(2 * math.pi * p);
      final eased = Curves.easeInOutCubic.transform(spread);
      final radius = outer * (0.12 + 0.62 * eased);
      final angle = 2 * math.pi * i / _dots + t * math.pi;
      final dot = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      final color = Color.lerp(from, to, i / (_dots - 1))!;
      canvas.drawCircle(
        dot,
        base * (0.75 + 0.5 * eased),
        Paint()..color = color.withValues(alpha: 0.55 + 0.45 * eased),
      );
    }
  }

  @override
  bool shouldRepaint(_GatherPainter old) =>
      old.t != t || old.from != from || old.to != to;
}
