import 'package:flutter/widgets.dart';

/// 이 폭보다 좁으면 모바일 배치(하단 탭, 한 열)로 바뀐다.
const kNarrow = 800.0;

/// 모든 화면이 공유하는 가운데 컨테이너 폭. 넓은 화면에서도 이 폭 밖으로 늘어나지 않는다.
const kContentWidth = 880.0;

/// 글자(제목 · 설명 · 머리글 · 안내)의 좌우 여백. 좁은 화면(모바일)에서만 쓴다.
/// 목록 · 격자 · 카드 · 입력칸 같은 상자는 좌우 여백 없이 화면 너비를 꽉 채우고, 글자만 이 여백을 둔다.
double textGutter(BuildContext context) {
  // 페이지 틀이 이미 좌우 여백을 두었으면(PageFrame.inset) 글자 여백은 더 두지 않는다.
  if (context.getInheritedWidgetOfExactType<InsetScope>() != null) return 0;
  return MediaQuery.sizeOf(context).width < kNarrow ? 16 : 0;
}

/// 이 아래는 페이지 틀이 좌우 여백을 이미 두었다는 표시 ([textGutter]가 0이 된다).
class InsetScope extends InheritedWidget {
  const InsetScope({super.key, required super.child});

  @override
  bool updateShouldNotify(InsetScope old) => false;
}

/// 글자를 좌우 여백 안쪽에 놓는다 ([textGutter]). 상자가 화면 너비를 채우는 쪽에서 글자만 감쌀 때 쓴다.
class Gutter extends StatelessWidget {
  const Gutter({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: textGutter(context)),
    child: child,
  );
}

/// 화면 폭에 따른 좌우 여백.
double pagePadding(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  if (w < kNarrow) return 16;
  if (w < 1100) return 24;
  return 32;
}
