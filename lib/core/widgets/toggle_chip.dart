import 'package:flutter/material.dart';

import '../icons.dart';
import '../theme.dart';

/// 켜고 끄는 조건 버튼 (예: 마감 제외). 테두리 있는 알약 모양에 앞쪽 체크 표시가 있어 눌러서 바꾸는 것임을 알린다.
/// 켜지면 체크가 채워지고, 옅은 강조색 바탕과 굵은 글씨로 바뀐다. 글자는 검은색이다.
class ToggleChip extends StatelessWidget {
  const ToggleChip({
    super.key,
    required this.label,
    required this.on,
    required this.onTap,
  });

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final radius = BorderRadius.circular(999);
    return Semantics(
      button: true,
      toggled: on,
      label: label,
      child: Material(
        color: on ? palette.brand.withValues(alpha: 0.12) : palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: on ? palette.brand : palette.border,
            width: on ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  on ? AppIcons.checkCircleFill : AppIcons.checkCircle,
                  size: 18,
                  color: on ? palette.brand : palette.muted,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: 13.5,
                    fontWeight: on ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
