import 'package:flutter/material.dart';

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
    this.isNew = false,
  });

  final Member me;
  final List<PageConfig> pages;
  final String pageId;

  /// 아직 저장하지 않은 새 페이지인가 (저장 버튼을 눌러야 만들어진다).
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    // 스크롤 영역은 왼쪽 메뉴와 오른쪽 계정 띠를 뺀 폭 전체를 쓰고, 글 칸의 가운데 정렬은 편집기 안에서 한다.
    // 다른 페이지로 바뀌면 편집 상태를 새로 시작한다.
    return PageLayoutEditor(
      key: ValueKey(pageId),
      me: me,
      pages: pages,
      pageId: pageId,
      isNew: isNew,
    );
  }
}
