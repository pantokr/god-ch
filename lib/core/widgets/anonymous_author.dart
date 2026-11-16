import 'package:flutter/material.dart';

import '../icons.dart';
import '../theme.dart';

/// 작성자를 비공개로 한 글에서 다른 교인에게 보이는 글쓴이 이름.
const anonymousName = '익명';

/// 작성자가 가려진 글의 둥근 사진 자리: 프로필 사진 대신 사람 모양만 보인다.
class AnonymousAvatar extends StatelessWidget {
  const AnonymousAvatar({super.key, required this.radius});

  final double radius;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return CircleAvatar(
      radius: radius,
      backgroundColor: palette.border,
      child: Icon(AppIcons.user, size: radius * 1.2, color: palette.muted),
    );
  }
}
