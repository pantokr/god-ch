import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/format.dart';
import '../../../core/icons.dart';
import '../../../data/models/member.dart';
import '../../../data/models/prayer.dart';
import 'reaction_bar.dart';

/// 기도 화면의 바탕색: 포스트잇이 붙어 있는 게시판 색. 상단 바와 하단 바까지 같은 색을 써서
/// 화면에 배경색이 하나만 보이게 한다.
Color prayerBoardColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF2A2520)
    : const Color(0xFFEFE7D8);

/// 기도 화면 배경 효과: 종이 같은 점 무늬 위로 은은한 빛무리가 천천히 떠다닌다.
/// 시스템에서 애니메이션을 끈 경우에는 멈춰 있다.
/// 기도 화면의 포스트잇(떠다니는 카드 · 게시판 배경) 사용 여부. false이면 알록달록을 골라도 카드 격자만 보인다.
/// 다시 켜려면 true로 바꾼다 (스위치 · 배경이 함께 돌아온다).
const kPostItEnabled = false;

class PrayerBoardBackground extends StatefulWidget {
  const PrayerBoardBackground({super.key});

  @override
  State<PrayerBoardBackground> createState() => _PrayerBoardBackgroundState();
}

class _PrayerBoardBackgroundState extends State<PrayerBoardBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 50),
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _BoardPainter(_c, dark),
        ),
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter(this.animation, this.dark) : super(repaint: animation);

  final Animation<double> animation;
  final bool dark;

  // 빛무리: (가로 위치, 세로 위치, 반지름, 색, 움직임 위상)
  static const _glows = [
    (0.15, 0.12, 120.0, Color(0xFFFFD54F), 0.0),
    (0.85, 0.22, 150.0, Color(0xFFF48FB1), 1.3),
    (0.35, 0.50, 110.0, Color(0xFF81D4FA), 2.1),
    (0.80, 0.62, 130.0, Color(0xFFA5D6A7), 3.0),
    (0.10, 0.80, 140.0, Color(0xFFFFCC80), 4.2),
    (0.60, 0.92, 120.0, Color(0xFFCE93D8), 5.1),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // 종이 점 무늬
    final dot = Paint()
      ..color = (dark ? Colors.white : const Color(0xFF8D6E63)).withValues(
        alpha: dark ? 0.05 : 0.10,
      );
    for (var y = 14.0; y < size.height; y += 24) {
      for (var x = 14.0; x < size.width; x += 24) {
        canvas.drawCircle(Offset(x, y), 0.9, dot);
      }
    }
    // 떠다니는 빛무리
    final t = animation.value * 2 * math.pi;
    for (final (fx, fy, r, color, phase) in _glows) {
      final c = Offset(
        size.width * fx + math.sin(t + phase) * size.width * 0.06,
        size.height * fy + math.cos(t * 0.8 + phase) * size.height * 0.04,
      );
      final alpha = dark ? 0.16 : 0.34;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r));
      canvas.drawCircle(c, r, paint);
    }
  }

  @override
  bool shouldRepaint(_BoardPainter old) => old.dark != dark;
}

/// 기도제목을 포스트잇 여러 장으로 붙여 놓은 게시판. 두 줄(넓은 화면은 세 줄)로 늘어서고,
/// 한 장씩 살짝 기울어져 있다.
class PostItWall extends StatelessWidget {
  const PostItWall({
    super.key,
    required this.prayers,
    required this.me,
    required this.showReactions,
    this.authorNames = const {},
  });

  final List<Prayer> prayers;
  final Member me;
  final bool showReactions;

  /// 교역자 화면에서 카드에 작성자 이름을 덧붙일 때 쓴다 (uid → 이름).
  final Map<String, String> authorNames;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        const side = 16.0;
        const gap = 18.0;
        final cols = box.maxWidth < 600 ? 2 : 3;
        final w = (box.maxWidth - side * 2 - gap * (cols - 1)) / cols;
        return Padding(
          // 아래는 떠 있는 기도 요청 버튼에 마지막 장이 가리지 않게 비운다.
          padding: const EdgeInsets.fromLTRB(side, 24, side, 96),
          child: Wrap(
            spacing: gap,
            runSpacing: gap + 6,
            children: [
              for (final p in prayers)
                SizedBox(
                  width: w,
                  height: w * PostItNote.ratio,
                  child: PostItNote(
                    prayer: p,
                    me: me,
                    showReactions: showReactions && p.isPublic,
                    subtitle: authorNames.isEmpty
                        ? null
                        : (authorNames[p.authorId] ?? '알 수 없음'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// 기도제목 한 장: 정사각형에 가까운 포스트잇. 종이 색은 글마다 정해져 있다.
/// 위쪽 끈끈이 띠의 그늘, 압정(또는 테이프), 아래 모서리의 말린 귀퉁이, 겹겹의 그림자로 종이 느낌을 낸다.
/// 크기는 바깥에서 정한다 (부모가 준 폭 · 높이를 가득 채운다).
class PostItNote extends StatelessWidget {
  const PostItNote({
    super.key,
    required this.prayer,
    required this.me,
    this.showReactions = false,
    this.subtitle,
    this.lift = 1,
  });

  /// 높이 ÷ 폭. 정사각형에 가깝다.
  static const ratio = 1.1;

  final Prayer prayer;
  final Member me;
  final bool showReactions;

  /// 날짜 옆에 덧붙일 문구 (예: 교역자 화면의 작성자 이름).
  final String? subtitle;

  /// 그림자의 세기. 공중에 떠 있는 카드는 더 크게 줘서 높이 떠 보이게 한다.
  final double lift;

  static const _colors = [
    Color(0xFFFFF176), // 노랑
    Color(0xFFF8BBD0), // 분홍
    Color(0xFFC5E1A5), // 연두
    Color(0xFF81D4FA), // 하늘
    Color(0xFFFFCC80), // 주황
    Color(0xFFCE93D8), // 연보라
  ];

  // 포스트잇 위의 글자는 어느 모드에서든 짙은 갈색이다 (종이 색이 늘 밝으므로).
  static const _ink = Color(0xFF3B3224);
  static const _soft = Color(0xFF7A6A52);

  @override
  Widget build(BuildContext context) {
    final hash = prayer.id.hashCode.abs();
    final color = _colors[hash % _colors.length];
    // 종이 위쪽은 밝고 아래로 갈수록 조금 짙다.
    final light = Color.lerp(color, Colors.white, 0.28)!;
    final deep = Color.lerp(color, const Color(0xFF8D6E63), 0.12)!;
    // -0.03 ~ +0.03 라디안: 한 장씩 조금씩 다르게 기울인다.
    final tilt = ((hash ~/ 7) % 5 - 2) * 0.015;
    final pinned = hash % 3 != 0; // 압정이거나 테이프
    final badges = [
      if (prayer.affiliationId != null) '소속',
      if (!prayer.isPublic) '교역자 전용',
      if (prayer.deleted) '삭제됨',
    ];
    return Transform.rotate(
      angle: tilt,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 종이
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [light, color, deep],
                  stops: const [0, 0.55, 1],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x2E000000),
                    blurRadius: 16 * lift,
                    offset: Offset(3 * lift, 9 * lift),
                  ),
                  const BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 3,
                    offset: Offset(1, 2),
                  ),
                ],
              ),
            ),
          ),
          // 위쪽 끈끈이 띠의 그늘
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 22,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.10),
                    Colors.black.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          // 아래 오른쪽 말린 귀퉁이
          const Positioned(right: 0, bottom: 0, child: _Curl()),
          // 내용
          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                // 주소로 이동하므로 뒤로가기로 목록에 돌아온다. 이미 가진 글은 함께 넘겨 바로 보여준다.
                onTap: () => context.push(
                  Routes.prayer(me.churchId, prayer.id),
                  extra: prayer,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 24, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (badges.isNotEmpty) ...[
                        Text(
                          badges.join(' · '),
                          style: const TextStyle(
                            color: _soft,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                      ],
                      Text(
                        prayer.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // 남는 높이만큼 본문 줄을 채우고 넘치면 말줄임표로 줄인다.
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, body) {
                            const bodySize = 13.5;
                            const bodyHeight = 1.5;
                            final lines = math.max(
                              1,
                              (body.maxHeight / (bodySize * bodyHeight))
                                  .floor(),
                            );
                            return Text(
                              prayer.content,
                              maxLines: lines,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _ink,
                                fontSize: bodySize,
                                height: bodyHeight,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              [
                                fmtDateTime(prayer.createdAt),
                                ?subtitle,
                              ].join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _soft,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          if (prayer.hasUnreadResponse &&
                              prayer.authorId == me.id)
                            const Icon(
                              AppIcons.envelopeSimple,
                              size: 14,
                              color: _ink,
                            ),
                        ],
                      ),
                      if (showReactions) ...[
                        const SizedBox(height: 6),
                        ReactionBar(churchId: me.churchId, prayerId: prayer.id),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 위에 붙은 압정 또는 테이프
          Positioned(
            top: pinned ? -7 : -8,
            left: 0,
            right: 0,
            child: Center(child: pinned ? const _Pin() : const _Tape()),
          ),
        ],
      ),
    );
  }
}

/// 포스트잇 위에 꽂힌 압정.
class _Pin extends StatelessWidget {
  const _Pin();

  @override
  Widget build(BuildContext context) => Container(
    width: 16,
    height: 16,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        center: Alignment(-0.4, -0.4),
        colors: [Color(0xFFFF8A80), Color(0xFFD32F2F)],
      ),
      boxShadow: [
        BoxShadow(
          color: Color(0x55000000),
          blurRadius: 4,
          offset: Offset(1, 3),
        ),
      ],
    ),
  );
}

/// 포스트잇 위에 붙은 반투명 테이프.
class _Tape extends StatelessWidget {
  const _Tape();

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: -0.06,
    child: Container(
      width: 54,
      height: 18,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 2)],
      ),
    ),
  );
}

/// 아래 오른쪽 모서리가 살짝 말려 올라간 귀퉁이.
class _Curl extends StatelessWidget {
  const _Curl();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(24, 24), painter: _CurlPainter());
}

class _CurlPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 말려 올라온 뒷면(밝은 삼각형)과 그 아래 그림자.
    final fold = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawShadow(fold, Colors.black.withValues(alpha: 0.5), 3, false);
    canvas.drawPath(
      fold,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Colors.white.withValues(alpha: 0.85),
            const Color(0xFFD7CCC8),
          ],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
