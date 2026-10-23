import 'package:flutter/material.dart';

import '../../../core/layout/page_frame.dart';
import '../../../data/models/department.dart';
import '../../../data/models/member.dart';
import '../../../data/models/page_layout.dart';
import 'block_views.dart';
import 'content_widgets.dart';

/// 교회 페이지 하나를 그린다: 교역자가 정한 구조(블록)들을 위에서 아래로 쌓는다.
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
      child: PageFrame(
        child: ChurchPageBody(page: page, me: me, department: department),
      ),
    );
  }
}

/// 페이지의 구조들을 위에서 아래로 쌓은 본문. 스크롤 없이 높이만큼 늘어나서,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (page.blocks.isEmpty)
          EmptyHint(
            me.isStaff
                ? '아직 구조가 없어요.\n"페이지 편집"에서 이 페이지에 구조를 쌓아 보세요.'
                : '아직 준비 중인 페이지예요.',
          ),
        for (final b in page.blocks)
          BlockView(block: b, me: me, department: department),
        const SizedBox(height: 24),
      ],
    );
  }
}
