import 'package:flutter/material.dart';

import '../theme.dart';
import 'like_heart.dart';
import 'stat_icons.dart';

/// 좋아요 버튼: 테두리 있는 알약 안에 하트와 "좋아요 N"이 있어 눌러서 바꾸는 것임을 알린다.
/// 누르면 하트가 튀고, 눌러 둔 상태는 옅은 붉은 바탕과 붉은 테두리로 보인다. [onTap]이 없으면 비활성이다.
class LikeButton extends StatelessWidget {
  const LikeButton({
    super.key,
    required this.liked,
    required this.count,
    required this.onTap,
  });

  final bool liked;
  final int count;
  final VoidCallback? onTap;

  static const _red = Color(0xFFE5484D);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final enabled = onTap != null;
    final radius = BorderRadius.circular(999);
    return Semantics(
      button: true,
      toggled: liked,
      label: liked ? '좋아요 취소' : '좋아요',
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Material(
          color: liked ? _red.withValues(alpha: 0.1) : palette.surface,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(
              color: liked ? _red : palette.border,
              width: liked ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LikeHeart(
                    liked: liked,
                    size: 20,
                    unlikedColor: palette.muted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '좋아요 ${StatIcons.compact(count)}',
                    style: TextStyle(
                      color: palette.ink,
                      fontSize: 14,
                      fontWeight: liked ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
