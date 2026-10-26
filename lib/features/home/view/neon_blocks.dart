import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../data/models/prayer.dart';

/// 네온 계열 디자인의 색 구성. 앱 테마(라이트·다크)와 상관없이 항상 어두운 바탕에 빛나는 두 색을 쓴다.
/// 디자인 id는 `네온종류_모양`이다 (예: `cyber_list`, `neon_grid`).
@immutable
class NeonScheme {
  const NeonScheme({
    required this.night,
    required this.night2,
    required this.a,
    required this.b,
    required this.text,
    required this.sub,
  });

  /// 바탕(어두운 면)과 그 그라데이션 끝색.
  final Color night;
  final Color night2;

  /// 빛나는 주색 · 보조색.
  final Color a;
  final Color b;

  /// 본문 글자 · 보조 글자.
  final Color text;
  final Color sub;

  /// 보라 밤하늘 + 라임 + 핫핑크 (달력의 네온과 같은 색).
  static const neon = NeonScheme(
    night: Color(0xFF14121F),
    night2: Color(0xFF241C45),
    a: Color(0xFFC6FF3D),
    b: Color(0xFFFF4F8B),
    text: Color(0xFFF1EEFF),
    sub: Color(0xFF9D97C9),
  );

  /// 심해 남색 + 시안 + 마젠타.
  static const cyber = NeonScheme(
    night: Color(0xFF071A2B),
    night2: Color(0xFF0E2F4A),
    a: Color(0xFF22E4FF),
    b: Color(0xFFFF2BD6),
    text: Color(0xFFE6FBFF),
    sub: Color(0xFF7FB4C9),
  );

  /// 붉은 밤 + 주황 + 산호빛 핑크.
  static const flare = NeonScheme(
    night: Color(0xFF1F0F1A),
    night2: Color(0xFF3A1426),
    a: Color(0xFFFF9F1C),
    b: Color(0xFFFF3D6E),
    text: Color(0xFFFFF1E6),
    sub: Color(0xFFD9A08A),
  );

  /// 디자인 id가 네온 계열이면 그 색 구성, 아니면 null.
  static NeonScheme? of(String variant) {
    if (variant.startsWith('neon_')) return neon;
    if (variant.startsWith('cyber_')) return cyber;
    if (variant.startsWith('flare_')) return flare;
    return null;
  }

  LinearGradient get body => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [night, night2],
  );

  LinearGradient get glowBar => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [a, b],
  );

  /// 빛나는 테두리 + 번지는 그림자.
  BoxDecoration card({double radius = AppRadius.card}) => BoxDecoration(
    gradient: body,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: a.withValues(alpha: 0.55), width: 1.2),
    boxShadow: [
      BoxShadow(
        color: a.withValues(alpha: 0.22),
        blurRadius: 18,
        offset: const Offset(0, 6),
      ),
    ],
  );
}

/// 디자인 id의 모양 부분(`_` 뒤): list · compact · grid · cards · bubbles.
String neonShape(String variant) => variant.split('_').last;

/// 메신저 말풍선: 어두운 말풍선, 내 글은 주색 테두리가 더 강하다.
class NeonPrayerBubble extends StatelessWidget {
  const NeonPrayerBubble({
    super.key,
    required this.scheme,
    required this.prayer,
    required this.mine,
    required this.onTap,
  });

  final NeonScheme scheme;
  final Prayer prayer;
  final bool mine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glow = mine ? scheme.b : scheme.a;
    final radius = BorderRadius.circular(AppRadius.card + 2);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: scheme.body,
              borderRadius: radius,
              border: Border.all(
                color: glow.withValues(alpha: 0.7),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: glow.withValues(alpha: 0.28),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prayer.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: glow,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          prayer.content,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: scheme.text),
                        ),
                        if (prayer.createdAt != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            fmtDate(prayer.createdAt!),
                            style: TextStyle(color: scheme.sub, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
