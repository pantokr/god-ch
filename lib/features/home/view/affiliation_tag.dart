import 'package:flutter/material.dart';

import '../../../core/theme.dart';

/// 글의 소속을 이름 옆에 붙이는 작은 표시 (예: 청년회). 소속이 없는 글(교회 전체)에는 쓰지 않는다.
class AffiliationTag extends StatelessWidget {
  const AffiliationTag(this.name, {super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.brand.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: palette.ink,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// 글의 소속 표시 문구: 소속이 없으면(교회 전체 공개) "전체", 있으면 소속 이름. 이름을 아직 모르면 null.
String? affiliationLabel(Map<String, String> names, String? affiliationId) =>
    affiliationId == null ? '전체' : names[affiliationId];
