import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../data/models/member.dart';
import '../../../data/models/prayer.dart';
import 'postit_card.dart';

/// 최신 기도 요청 몇 장을 공중에 둥둥 떠다니는 카드로 보여준다. 카드를 누르면 기도 상세로 간다.
/// 카드는 정해진 자리 둘레를 천천히 오르내리며 살짝 기운다 (시스템에서 애니메이션을 끈 경우는 멈춰 있다).
class FloatingPrayers extends StatelessWidget {
  const FloatingPrayers({
    super.key,
    required this.prayers,
    required this.me,
    this.count = 4,
    this.fullScreen = false,
  });

  final Stream<List<Prayer>> prayers;
  final Member me;

  /// 띄울 카드 수 (최신 글부터).
  final int count;

  /// 화면 전체를 쓰는 기도 화면: 따로 틀(패널)을 두르지 않고 화면의 배경 위에 카드만 떠다닌다.
  final bool fullScreen;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Prayer>>(
      stream: prayers,
      builder: (context, snap) {
        if (snap.hasError) return Text('불러오지 못했습니다\n${snap.error}');
        if (!snap.hasData) {
          return const SizedBox(
            height: 240,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final items = snap.data!.take(count).toList();
        if (items.isEmpty) return _EmptyStage(fullScreen: fullScreen);
        return _Stage(prayers: items, me: me, fullScreen: fullScreen);
      },
    );
  }
}

class _EmptyStage extends StatelessWidget {
  const _EmptyStage({required this.fullScreen});

  final bool fullScreen;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      alignment: Alignment.center,
      decoration: fullScreen ? null : _stageDecoration(context),
      child: Text(
        '아직 기도 요청이 없어요.\n첫 기도를 요청해 보세요.',
        textAlign: TextAlign.center,
        style: TextStyle(color: context.palette.muted, height: 1.6),
      ),
    );
  }
}

BoxDecoration _stageDecoration(BuildContext context) {
  final p = context.palette;
  return BoxDecoration(
    borderRadius: BorderRadius.circular(AppRadius.panel),
    gradient: RadialGradient(
      center: const Alignment(-0.5, -0.6),
      radius: 1.3,
      colors: [
        Color.alphaBlend(p.brand.withValues(alpha: 0.14), p.surface),
        Color.alphaBlend(p.accent.withValues(alpha: 0.08), p.bg),
      ],
    ),
    border: Border.all(color: p.border),
  );
}

class _Stage extends StatefulWidget {
  const _Stage({
    required this.prayers,
    required this.me,
    required this.fullScreen,
  });

  final List<Prayer> prayers;
  final Member me;
  final bool fullScreen;

  @override
  State<_Stage> createState() => _StageState();
}

class _StageState extends State<_Stage> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
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
    final n = widget.prayers.length;
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final narrow = w < 560;
        // 카드는 정사각형에 가까운 포스트잇이다.
        final cardW = narrow
            ? math.min(w * 0.56, 230.0)
            : math.min(250.0, w * 0.3);
        final cardH = cardW * PostItNote.ratio;
        // 카드 자리: 넓은 화면은 두 줄에 엇갈려, 좁은 화면은 좌우로 번갈아 한 줄씩 내려간다.
        final rows = narrow ? n : (n + 1) ~/ 2;
        final rowGap = narrow ? 36.0 : 56.0;
        final height = 32 + rows * cardH + (rows - 1) * rowGap + 40;
        Offset slot(int i) {
          if (narrow) {
            return Offset(i.isEven ? 0 : w - cardW, 16 + i * (cardH + rowGap));
          }
          final row = i ~/ 2;
          final left = i.isEven;
          final shift = row.isOdd ? 36.0 : 0.0;
          return Offset(
            left ? 8 + shift : w - cardW - 8 - shift,
            16 + row * (cardH + rowGap) + (left ? 0 : 36),
          );
        }

        return Container(
          height: height,
          decoration: widget.fullScreen ? null : _stageDecoration(context),
          clipBehavior: widget.fullScreen ? Clip.none : Clip.antiAlias,
          child: Stack(
            children: [
              for (var i = 0; i < n; i++)
                _Floating(
                  animation: _c,
                  phase: i * 1.7,
                  origin: slot(i),
                  tilt: i.isEven ? -0.025 : 0.025,
                  child: SizedBox(
                    width: cardW,
                    height: cardH,
                    // 공중에 떠 있으니 그림자를 더 크게 준다.
                    child: PostItNote(
                      prayer: widget.prayers[i],
                      me: widget.me,
                      lift: 1.8,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// 자리 둘레를 천천히 떠다니는 움직임 (카드마다 위상이 달라 따로 논다).
class _Floating extends StatelessWidget {
  const _Floating({
    required this.animation,
    required this.phase,
    required this.origin,
    required this.tilt,
    required this.child,
  });

  final Animation<double> animation;
  final double phase;
  final Offset origin;
  final double tilt;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = animation.value * 2 * math.pi + phase;
        return Positioned(
          left: origin.dx + math.cos(t * 0.8) * 8,
          top: origin.dy + math.sin(t) * 12,
          child: Transform.rotate(
            angle: tilt + math.sin(t * 0.7) * 0.012,
            child: child,
          ),
        );
      },
    );
  }
}
