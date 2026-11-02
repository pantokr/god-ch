import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/widgets/thumbnail_avatar.dart';

/// 교인 한 명의 둥근 프로필 이미지. 글 · 모임 문서에는 쓴 사람의 uid와 이름만 있으므로,
/// 사진은 교회의 사람 목록에서 uid로 찾아 보여주고 사진이 없으면 이름의 머리글자를 보여준다.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    required this.churchId,
    required this.uid,
    required this.name,
    this.radius = 20,
  });

  final String churchId;
  final String uid;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final photos = AppScope.read(context).people.photos(churchId);
    return ValueListenableBuilder<Map<String, String>>(
      valueListenable: photos,
      builder: (context, map, _) =>
          ThumbnailAvatar(name: name, url: map[uid] ?? '', radius: radius),
    );
  }
}
