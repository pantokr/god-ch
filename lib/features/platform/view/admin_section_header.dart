import 'package:flutter/material.dart';

import '../../../core/theme.dart';

/// 박스 안 맨 위의 제목 줄 (교회 회원 관리의 박스 제목과 같은 모양): 제목 · 건수 표시, 아래에 구분선.
/// 처리할 건이 있으면 [highlight]로 건수 표시를 코랄로 강조한다.
class AdminSectionHeader extends StatelessWidget {
  const AdminSectionHeader({
    super.key,
    required this.title,
    required this.count,
    this.highlight = false,
  });

  final String title;
  final int count;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = highlight && count > 0 ? palette.accent : palette.brand;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
