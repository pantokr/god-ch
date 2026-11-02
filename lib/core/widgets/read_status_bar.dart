import 'package:flutter/material.dart';

/// 읽음 · 신규 상태 바 사용 여부. false이면 중보기도 · 말씀묵상 카드에 바가 나오지 않는다.
/// 다시 켜려면 true로 바꾼다.
const kReadBarEnabled = false;

/// 목록 카드 맨 위 가장자리에 붙는 상태 바: 카드 너비를 전부 차지하고 가운데에 흰 글씨가 있다.
/// 읽은 글은 짙은 회색 "읽음", 7일 안에 올라온 안 읽은 글은 붉은 "신규"이고, 그보다 오래된 안 읽은 글은 바가 없다. 카드의 안쪽 여백(좌우 16)까지 덮는다.
class ReadStatusBar extends StatelessWidget {
  const ReadStatusBar({super.key, required this.label, required this.color});

  /// 읽은 글: 회색 "읽음" 바.
  const ReadStatusBar.read({super.key, required this.color}) : label = '읽음';

  /// 안 읽은 새 글: 붉은 "신규" 바.
  const ReadStatusBar.fresh({super.key})
    : label = '신규',
      color = const Color(0xFFE5484D);

  final String label;
  final Color color;

  static const height = 26.0;

  /// 이 기간 안에 올라온 글만 "신규"로 친다.
  static const freshWithin = Duration(days: 7);

  /// [createdAt]이 신규 기간 안인가. 올린 시각을 모르면 신규로 보지 않는다.
  static bool isFresh(DateTime? createdAt) =>
      createdAt != null && DateTime.now().difference(createdAt) < freshWithin;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => SizedBox(
        height: height,
        child: OverflowBox(
          minWidth: box.maxWidth + 32,
          maxWidth: box.maxWidth + 32,
          child: Container(
            height: height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(3),
              ),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
