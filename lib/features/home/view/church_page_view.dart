import 'package:flutter/material.dart';

import '../../../core/layout/responsive.dart';
import '../../../data/models/department.dart';
import '../../../data/models/member.dart';
import '../../../data/models/page_layout.dart';
import 'block_views.dart';
import 'content_widgets.dart';

/// 교회 페이지 하나를 그린다: 교역자가 고른 레이아웃 하나를 보여준다.
class ChurchPageView extends StatelessWidget {
  const ChurchPageView({
    super.key,
    required this.page,
    required this.me,
    this.department,
    this.fullScreen = false,
  });

  final PageConfig page;
  final Member me;
  final Department? department;

  /// 페이지 제목도 바깥 여백도 없이 화면 전체를 쓴다 (기도 · 말씀 탭).
  final bool fullScreen;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: fullScreen ? 0 : 28),
        child: ChurchPageBody(
          page: page,
          me: me,
          department: department,
          fullScreen: fullScreen,
        ),
      ),
    );
  }
}

/// 페이지의 레이아웃 본문. 스크롤 없이 높이만큼 늘어나서,
/// 실제 페이지와 페이지 편집의 미리보기가 함께 쓴다.
class ChurchPageBody extends StatelessWidget {
  const ChurchPageBody({
    super.key,
    required this.page,
    required this.me,
    this.department,
    this.fullScreen = false,
  });

  final PageConfig page;
  final Member me;
  final Department? department;
  final bool fullScreen;

  @override
  Widget build(BuildContext context) {
    // 화면 전체 폭을 쓰되, 글과 일반 구조는 가운데 [kContentWidth] 칸에 맞춘다 (좌우 [inset]).
    // 옆으로 미는 카드 줄만 [inset]에서 시작해 화면 끝까지 이어져 칸 바깥에서도 스크롤된다.
    final pad = pagePadding(context);
    return LayoutBuilder(
      builder: (context, box) {
        final inset = fullScreen
            ? 0.0
            : pad + ((box.maxWidth - kContentWidth) / 2).clamp(0, 1e9);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (page.blocks.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: inset),
                child: EmptyHint(me.isStaff ? '페이지 편집에서 구조 추가' : '준비 중'),
              )
            else
              for (var i = 0; i < page.blocks.length; i++) ...[
                if (i > 0) const SizedBox(height: 16),
                BlockView(
                  key: ValueKey(page.blocks[i].id),
                  block: page.blocks[i],
                  me: me,
                  department: department,
                  inset: inset,
                  fullScreen: fullScreen,
                ),
              ],
            SizedBox(height: fullScreen ? 0 : 24),
          ],
        );
      },
    );
  }
}
