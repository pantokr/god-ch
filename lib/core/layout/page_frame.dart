import 'package:flutter/material.dart';

import '../theme.dart';
import 'responsive.dart';

/// 가운데 정렬된 최대 폭 콘텐츠 영역.
class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.child,
    this.maxWidth = kContentWidth,
    this.verticalPadding = 28,
  });

  final Widget child;
  final double maxWidth;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    final pad = pagePadding(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: pad,
            vertical: verticalPadding,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// 본문 위에 놓는 페이지 제목 줄. 오른쪽에 주요 버튼을 둘 수 있다.
class PageTitle extends StatelessWidget {
  const PageTitle({super.key, required this.title, this.subtitle, this.action});

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      subtitle!,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ),
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(width: 12), ?action],
        ],
      ),
    );
  }
}
