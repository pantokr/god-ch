import 'package:flutter/material.dart';

import '../theme.dart';

/// 신규 표시 사용 여부. false이면 중보기도 · 말씀묵상 카드에 표시가 나오지 않는다. 신규만 쓰고 읽음 표시는 두지 않는다.
/// 다시 켜려면 true로 바꾼다.
const kReadBarEnabled = true;

/// 신규 글 표시: 제목 왼쪽의 작은 붉은 점 하나.
/// 7일 안에 올라온 안 읽은 글에만 붙고, 글을 한 번 열면 그 사용자에게서 사라진다.
class ReadStatusBar extends StatelessWidget {
  const ReadStatusBar.fresh({super.key});

  /// 점의 지름.
  static const size = 8.0;

  /// 이 기간 안에 올라온 글만 "신규"로 친다.
  static const freshWithin = Duration(days: 7);

  /// [createdAt]이 신규 기간 안인가. 올린 시각을 모르면 신규로 보지 않는다.
  static bool isFresh(DateTime? createdAt) =>
      createdAt != null && DateTime.now().difference(createdAt) < freshWithin;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '신규',
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.like,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
