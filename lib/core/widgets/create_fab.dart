import 'package:flutter/material.dart';

import '../icons.dart';
import '../screen_style.dart';
import '../theme.dart';

/// 화면 오른쪽 아래에 떠 있는 새 글 버튼 (중보기도 요청 · 모임 만들기 · 말씀묵상 작성)
/// 세 버튼은 모양이 같다 (아이콘은 모두 더하기). 화면별 글씨 크기 설정은 받지 않는다..
/// 기본 플로팅 버튼 대신 앱의 그라데이션과 빛 번짐 그림자로 만든다.
/// 화면 [Stack]에 `Positioned(right: 16, bottom: 16, ...)`로 놓고, 목록 아래에는 [clearance]만큼 비운다.
class CreateFab extends StatelessWidget {
  const CreateFab({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = AppIcons.plus,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData icon;

  /// 마지막 줄이 버튼에 가리지 않도록 목록 아래에 비우는 높이.
  static const clearance = 88.0;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final radius = BorderRadius.circular(AppRadius.card);
    // 화면별 글씨 크기(개인 설정)와 상관없이 세 화면의 버튼 크기 · 글자가 같다.
    return ScreenStyle.unscaled(context, _button(context, palette, radius));
  }

  Widget _button(
    BuildContext context,
    AppPalette palette,
    BorderRadius radius,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppDepth.brand(context),
        borderRadius: radius,
        boxShadow: AppDepth.glow(context, strength: 0.9),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: palette.onBrand),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(color: palette.onBrand, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
