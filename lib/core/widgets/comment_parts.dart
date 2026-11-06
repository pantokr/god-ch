import 'package:flutter/material.dart';

import '../../features/people/view/person_popup.dart';
import '../format.dart';
import '../icons.dart';
import '../theme.dart';

/// 댓글 맨 위 카드: 아이콘과 "댓글 N", 글쓰기 칸([composer]), 불러오기 오류.
/// 모임 일정 · 중보기도 · 말씀묵상의 댓글이 같은 모양을 쓴다.
class CommentHeaderCard extends StatelessWidget {
  const CommentHeaderCard({
    super.key,
    required this.title,
    this.composer,
    this.hasError = false,
  });

  /// 예: "댓글 3".
  final String title;
  final Widget? composer;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(AppIcons.messageCircle, size: 18, color: palette.accent),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            if (composer != null) ...[const SizedBox(height: 12), composer!],
            if (hasError) ...[
              const SizedBox(height: 12),
              Text('불러오지 못했습니다', style: TextStyle(color: palette.muted)),
            ],
          ],
        ),
      ),
    );
  }
}

/// 댓글 한 건의 첫 줄: 이름(누르면 프로필) · 작성 시각 · 수정됨.
class CommentByline extends StatelessWidget {
  const CommentByline({
    super.key,
    required this.churchId,
    required this.uid,
    required this.name,
    required this.time,
    this.edited = false,
  });

  final String churchId;
  final String uid;
  final String name;
  final DateTime? time;
  final bool edited;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final small = TextStyle(color: palette.muted, fontSize: 12);
    return Row(
      children: [
        PersonTap(
          churchId: churchId,
          uid: uid,
          name: name,
          child: Text(
            name.isEmpty ? '이름 없음' : name,
            style: TextStyle(
              color: palette.brand,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(fmtDateTime(time), style: small),
        if (edited) ...[const SizedBox(width: 6), Text('수정됨', style: small)],
      ],
    );
  }
}
