import 'package:flutter/material.dart';

import '../icons.dart';
import '../theme.dart';

/// 소속 표시: 인디고 테두리의 각진 표 + 사람들 아이콘. 앱 어디서나 소속은 이 모양이다 (직급은 이름 앞 아이콘 [MemberMark]).
class AffiliationChip extends StatelessWidget {
  const AffiliationChip(this.name, {super.key, this.compact = false});

  final String name;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: palette.brand.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 9,
          vertical: compact ? 1.5 : 3.5,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.users, size: compact ? 11 : 13, color: palette.brand),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.brand,
                  fontSize: compact ? 11 : 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 소속들을 소속 모양([AffiliationChip])으로 나란히 보인다. 하나씩 차례로 살짝 커지며 떠오른다.
/// [names]가 비어 있으면 "전체"(교회 전체 공개) 하나가 보인다.
class AffiliationChips extends StatelessWidget {
  const AffiliationChips(this.names, {super.key});

  final List<String> names;

  @override
  Widget build(BuildContext context) {
    final shown = names.isEmpty ? const ['전체'] : names;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i < shown.length; i++)
          TweenAnimationBuilder<double>(
            key: ValueKey('${shown[i]}/$i'),
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 260 + 80 * i),
            curve: Curves.easeOutBack,
            builder: (context, t, child) => Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: Transform.scale(scale: 0.8 + 0.2 * t, child: child),
            ),
            child: AffiliationChip(shown[i]),
          ),
      ],
    );
  }
}

/// 소속을 고르는 칩 (여러 개 고를 수 있다): 고르면 인디고로 차오르며 체크가 나타난다.
class AffiliationChoiceChip extends StatelessWidget {
  const AffiliationChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? palette.brand.withValues(alpha: 0.14)
                : Colors.transparent,
            border: Border.all(
              color: selected ? palette.brand : palette.border,
              width: selected ? 1.6 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(
                          AppIcons.check,
                          size: 15,
                          color: palette.brand,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? palette.brand : palette.ink,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
