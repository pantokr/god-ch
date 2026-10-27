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
  });

  final PageConfig page;
  final Member me;
  final Department? department;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: ChurchPageBody(page: page, me: me, department: department),
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
  });

  final PageConfig page;
  final Member me;
  final Department? department;

  @override
  Widget build(BuildContext context) {
    // 화면 전체 폭을 쓰되, 글과 일반 구조는 가운데 [kContentWidth] 칸에 맞춘다 (좌우 [inset]).
    // 옆으로 미는 카드 줄만 [inset]에서 시작해 화면 끝까지 이어져 칸 바깥에서도 스크롤된다.
    final pad = pagePadding(context);
    return LayoutBuilder(
      builder: (context, box) {
        final inset = pad + ((box.maxWidth - kContentWidth) / 2).clamp(0, 1e9);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (page.layout == null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: inset),
                child: EmptyHint(
                  me.isStaff
                      ? '아직 레이아웃이 없어요.\n"페이지 편집"에서 이 페이지의 레이아웃을 골라 보세요.'
                      : '아직 준비 중인 페이지예요.',
                ),
              )
            else
              BlockView(
                block: page.layout!,
                me: me,
                department: department,
                inset: inset,
              ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}
