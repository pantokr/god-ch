import 'package:flutter/material.dart';

import '../../../core/layout/responsive.dart';
import '../../../data/models/member.dart';
import '../../../data/models/page_layout.dart';
import 'page_layout_editor.dart';

/// 한 페이지의 구성을 고치는 화면 틀. 페이지 목록에서 "수정"을 누르면 열린다.
class PageEditPage extends StatelessWidget {
  const PageEditPage({
    super.key,
    required this.me,
    required this.pages,
    required this.pageId,
  });

  final Member me;
  final List<PageConfig> pages;
  final String pageId;

  @override
  Widget build(BuildContext context) {
    final pad = pagePadding(context);
    final narrow = MediaQuery.sizeOf(context).width < kNarrow;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kContentWidth),
        child: Padding(
          padding: EdgeInsets.fromLTRB(pad, narrow ? 8 : 20, pad, 0),
          // 다른 페이지로 바뀌면 편집 상태를 새로 시작한다.
          child: PageLayoutEditor(
            key: ValueKey(pageId),
            me: me,
            pages: pages,
            pageId: pageId,
          ),
        ),
      ),
    );
  }
}
