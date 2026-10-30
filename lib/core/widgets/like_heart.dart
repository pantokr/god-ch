import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../icons.dart';

/// 좋아요 하트: 눌러서 채워지는 순간 하트가 통통 튀고 작은 하트들이 사방으로 퍼지며 사라진다.
/// 이 위젯은 모양만 맡는다: [liked]가 false에서 true로 바뀔 때 효과를 재생하므로,
/// 누르는 동작(IconButton · TextButton)은 밖에서 그대로 쓴다. 시스템에서 애니메이션을 끈 경우는 효과 없이 바뀐다.
class LikeHeart extends StatefulWidget {
  const LikeHeart({
    super.key,
    required this.liked,
    this.size = 22,
    this.likedColor = const Color(0xFFE5484D),
    this.unlikedColor,
    this.shadows,
  });

  final bool liked;
  final double size;

  /// 채워졌을 때의 색 (효과의 작은 하트도 같은 색).
  final Color likedColor;

  /// 비어 있을 때의 색. 없으면 주변 아이콘 색을 따른다.
  final Color? unlikedColor;

  /// 아이콘 그림자. 이미지 위에 올릴 때 배경 없이도 읽히게 한다.
  final List<Shadow>? shadows;

  @override
  State<LikeHeart> createState() => _LikeHeartState();
}

class _LikeHeartState extends State<LikeHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  /// 퍼지는 작은 하트의 개수.
  static const _sparks = 7;

  @override
  void didUpdateWidget(LikeHeart old) {
    super.didUpdateWidget(old);
    if (!old.liked &&
        widget.liked &&
        !MediaQuery.disableAnimationsOf(context)) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final base = widget.liked
        ? widget.likedColor
        : widget.unlikedColor ?? IconTheme.of(context).color;
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          // 통통: 커졌다가(1.0 → 1.45) 살짝 눌렸다가(0.9) 제자리로.
          final pop = _c.isAnimating
              ? TweenSequence<double>([
                  TweenSequenceItem(
                    tween: Tween(
                      begin: 1.0,
                      end: 1.45,
                    ).chain(CurveTween(curve: Curves.easeOut)),
                    weight: 30,
                  ),
                  TweenSequenceItem(
                    tween: Tween(
                      begin: 1.45,
                      end: 0.9,
                    ).chain(CurveTween(curve: Curves.easeInOut)),
                    weight: 30,
                  ),
                  TweenSequenceItem(
                    tween: Tween(
                      begin: 0.9,
                      end: 1.0,
                    ).chain(CurveTween(curve: Curves.easeOut)),
                    weight: 40,
                  ),
                ]).transform(t)
              : 1.0;
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (_c.isAnimating)
                for (var i = 0; i < _sparks; i++)
                  _spark(i, t, size, widget.likedColor),
              Transform.scale(
                scale: pop,
                child: Icon(
                  widget.liked ? AppIcons.heartFill : AppIcons.heart,
                  size: size,
                  color: base,
                  shadows: widget.shadows,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 하트 둘레로 퍼지는 작은 하트 하나: 중심에서 바깥으로 나가며 작아지고 흐려진다.
  Widget _spark(int i, double t, double size, Color color) {
    final angle = 2 * math.pi * i / _sparks - math.pi / 2;
    final out = Curves.easeOutCubic.transform(t);
    final dist = size * (0.55 + 0.75 * out);
    final fade = (1 - Curves.easeIn.transform(t)).clamp(0.0, 1.0);
    return Transform.translate(
      offset: Offset(math.cos(angle) * dist, math.sin(angle) * dist),
      child: Opacity(
        opacity: fade,
        child: Icon(
          AppIcons.heartFill,
          size: size * (0.38 - 0.18 * t),
          color: color,
        ),
      ),
    );
  }
}
