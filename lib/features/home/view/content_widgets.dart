import '../../../core/icons.dart';

import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../data/models/church_content.dart';

/// [ContentImage]에서 앱에 들어 있는 이미지를 가리키는 주소의 앞부분.
const kAssetImagePrefix = 'asset:';

/// 디자인 견본의 사진·영상 칸에 쓰는 대체 이미지들. 견본의 항목마다 돌아가며 쓴다.
const kSampleImages = [
  '${kAssetImagePrefix}assets/images/placeholder.jpg',
  '${kAssetImagePrefix}assets/images/sample_butterfly.jpg',
  '${kAssetImagePrefix}assets/images/sample_sphere.jpg',
];

/// 주소로 불러오는 이미지. 불러오지 못하면 빈 면을 보여준다.
/// 다른 사이트의 이미지가 막혀도(CORS) 웹에서는 `<img>`로 한 번 더 시도한다.
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
    // 'asset:경로'는 앱에 들어 있는 이미지다 (디자인 견본의 대체 이미지).
    if (u.startsWith(kAssetImagePrefix)) {
      return Image.asset(
        u.substring(kAssetImagePrefix.length),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => placeholder,
      );
    }
    return Image.network(
      u,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      errorBuilder: (_, _, _) => placeholder,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : placeholder,
    );
  }
}

/// 메인 페이지의 구역 제목과 "더보기".
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.onMore});

  final String title;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 36, bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontSize: 19),
            ),
          ),
          if (onMore != null)
            TextButton(
              onPressed: onMore,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [Text('더보기'), Icon(AppIcons.caretRight, size: 18)],
              ),
            ),
        ],
      ),
    );
  }
}

/// 내용이 없을 때의 안내.
class EmptyHint extends StatelessWidget {
  const EmptyHint(this.text, {super.key, this.height});

  final String text;

  /// 있으면 그 높이를 차지한다. 자료가 들어왔을 때와 같은 높이로 잡아 화면이 출렁이지 않게 한다.
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

/// 콘텐츠 스트림의 로딩·오류를 처리하고, 목록이 오면 [builder]로 그린다.
class ContentStream extends StatelessWidget {
  const ContentStream({
    super.key,
    required this.stream,
    required this.builder,
    this.loadingHeight = 120,
  });

  final Stream<List<ChurchContent>> stream;
  final Widget Function(BuildContext context, List<ChurchContent> items)
  builder;
  final double loadingHeight;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChurchContent>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return EmptyHint('불러오지 못했습니다\n${snap.error}');
        }
        final items = snap.data;
        if (items == null) {
          return SizedBox(
            height: loadingHeight,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        return builder(context, items);
      },
    );
  }
}

/// 일정 등에서 쓰는 월/일 배지. 포인트색 그라데이션과 그림자로 떠 있는 달력 한 장처럼 보인다.
class DateBadge extends StatelessWidget {
  const DateBadge(this.date, {super.key});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final radius = BorderRadius.circular(AppRadius.card + 2);
    return Container(
      width: 54,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: AppDepth.brand(context),
        boxShadow: [
          BoxShadow(
            color: palette.brand.withValues(alpha: 0.38),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.16),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.card + 2),
              ),
            ),
            child: Text(
              '${date.month}월',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.onBrand.withValues(alpha: 0.9),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Text(
              '${date.day}',
              style: TextStyle(
                color: palette.onBrand,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 짧은 요일 글자.
String weekdayLabel(DateTime d) => '월화수목금토일'[d.weekday - 1];

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
