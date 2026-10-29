import '../../../core/icons.dart';

import 'package:flutter/material.dart';

import '../../../core/theme.dart';

/// 주소로 불러오는 이미지. 불러오지 못하면 빈 면을 보여준다.
class ContentImage extends StatelessWidget {
  const ContentImage(this.url, {super.key, this.icon = AppIcons.image});

  final String? url;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: context.palette.brand.withValues(alpha: 0.08),
      child: Center(
        child: Icon(icon, color: context.palette.brand.withValues(alpha: 0.5)),
      ),
    );
    final u = url;
    if (u == null || u.isEmpty) return placeholder;
    return Image.network(
      u,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, _, _) => placeholder,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : placeholder,
    );
  }
}

/// 내용이 없을 때의 안내.
class EmptyHint extends StatelessWidget {
  const EmptyHint(this.text, {super.key, this.height});

  final String text;

  /// 있으면 그 높이를 차지한다.
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      alignment: height == null ? null : Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: context.palette.surface,
        border: Border.all(color: context.palette.border),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: context.palette.muted),
      ),
    );
  }
}

/// 폭에 따라 [wide]열 또는 [narrow]열로 나누어 놓는다 (좁은 폭은 560 미만).
class ColumnWrap extends StatelessWidget {
  const ColumnWrap({
    super.key,
    required this.children,
    this.wide = 3,
    this.narrow = 1,
    this.gap = 12,
  });

  final List<Widget> children;
  final int wide;
  final int narrow;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth < 560 ? narrow : wide;
        final w = (constraints.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final c in children) SizedBox(width: w, child: c)],
        );
      },
    );
  }
}
