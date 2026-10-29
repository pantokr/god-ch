import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/thumbnail_avatar.dart';

/// 관리 목록(교회 · 회원 · 인원)의 한 줄. 모든 목록이 같은 모양과 같은 높이를 쓴다.
/// 제목 아래에 정해진 두 줄([line1], [line2])이 항상 자리를 차지하므로, 정보가 없으면
/// 그 줄은 빈칸으로 남고 줄의 높이는 그대로다. 오른쪽에는 [trailing]을 놓는다.
class ManageListRow extends StatelessWidget {
  const ManageListRow({
    super.key,
    required this.leading,
    required this.title,
    this.badge,
    this.line1 = '',
    this.line2 = '',
    this.trailing = const [],
    this.onTap,
  });

  /// 모든 줄의 높이.
  static const height = 76.0;

  final Widget leading;
  final String title;

  /// 제목 옆의 작은 표시 (예: NEW).
  final String? badge;
  final String line1;
  final String line2;
  final List<Widget> trailing;
  final VoidCallback? onTap;

  /// 이름의 머리글자(또는 썸네일 이미지)를 담은 둥근 아이콘.
  /// [imageUrl]이 있으면 그 이미지(썸네일)를 보여준다.
  static Widget avatar(
    BuildContext context,
    String name, {
    String imageUrl = '',
  }) => ThumbnailAvatar(name: name, url: imageUrl);

  Widget _line(BuildContext context, String text) => Text(
    // 비어 있어도 한 줄 높이를 지키도록 보이지 않는 글자를 둔다.
    text.isEmpty ? ' ' : text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(color: context.palette.muted, fontSize: 13),
  );

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: palette.accent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(
                                AppRadius.control,
                              ),
                            ),
                            child: Text(
                              badge!,
                              style: TextStyle(
                                color: palette.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    _line(context, line1),
                    _line(context, line2),
                  ],
                ),
              ),
              ...trailing,
            ],
          ),
        ),
      ),
    );
  }
}
