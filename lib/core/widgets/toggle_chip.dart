import 'package:flutter/material.dart';

import '../icons.dart';
import '../theme.dart';

/// 읽음 제외 토글 사용 여부. false이면 중보기도 · 말씀묵상 정렬 줄에 버튼이 나오지 않는다.
/// 다시 켜려면 true로 바꾼다.
const kHideReadEnabled = false;

/// 눌러서 켜고 끄는 조건 하나 (예: "읽음 제외"): 정렬 줄과 같은 흰 바탕 · 얇은 테두리 상자 안에
/// 각진 작은 체크 칸과 글자가 있다. 켜지면 체크 칸이 진하게 채워지고 테두리와 글자가 진해진다.
/// 라이트 모드는 흰색, 다크 모드는 카드 바탕색이다.
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(AppRadius.control);
    return Material(
      color: dark ? palette.surface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: on ? palette.ink : palette.border),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(borderRadius: radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 각진 체크 칸.
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: on ? palette.ink : null,
                  border: Border.all(
                    color: on ? palette.ink : palette.muted,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: on
                    ? Icon(
                        AppIcons.check,
                        size: 12,
                        color: dark ? palette.surface : Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: on ? palette.ink : palette.muted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
