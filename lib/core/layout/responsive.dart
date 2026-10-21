import 'package:flutter/widgets.dart';

/// 이 폭보다 좁으면 모바일 배치(하단 탭, 한 열)로 바뀐다.
const kNarrow = 800.0;

/// 모든 화면이 공유하는 가운데 컨테이너 폭. 넓은 화면에서도 이 폭 밖으로 늘어나지 않는다.
const kContentWidth = 880.0;

/// 화면 폭에 따른 좌우 여백.
double pagePadding(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  if (w < kNarrow) return 16;
  if (w < 1100) return 24;
  return 32;
}
