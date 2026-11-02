import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/icons.dart';
import '../../../core/theme.dart';
import '../../../data/models/affiliation.dart';

/// 글 상세의 정보 줄 (중보기도 · 말씀묵상이 같은 모양을 쓴다):
/// 날짜와 시각 · 조회수 · 공개 여부(공개 / 교역자 전용) · 소속(없으면 "전체")을 한 줄에 하나씩 아래로 쌓는다 (모임 일정 상세의 정보 줄과 같은 모양).
class PostMeta extends StatefulWidget {
  const PostMeta({
    super.key,
    required this.churchId,
    required this.date,
    required this.isPrivate,
    this.affiliationId,
    this.views,
    this.color,
  });

  final String churchId;

  /// 날짜와 시각을 이미 다듬은 문구.
  final String date;
  final bool isPrivate;

  /// 글의 소속. 없으면 "전체".
  final String? affiliationId;

  /// 조회수. 없으면 보여주지 않는다.
  final int? views;

  /// 글자 · 아이콘 색. 없으면 보조 글자색이다.
  final Color? color;

  @override
  State<PostMeta> createState() => _PostMetaState();
}

class _PostMetaState extends State<PostMeta> {
  /// 소속 이름을 알기 위한 소속 목록 (한 번만 구독한다).
  late final Stream<List<Affiliation>> _affiliations = AppScope.read(context)
      .affiliations
      .affiliations(widget.churchId);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textColor = widget.color ?? palette.ink;
    final iconColor = widget.color ?? palette.muted;
    Widget item(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: textColor)),
          ),
        ],
      ),
    );
    return StreamBuilder<List<Affiliation>>(
      stream: widget.affiliationId == null ? null : _affiliations,
      builder: (context, snap) {
        final id = widget.affiliationId;
        final name = id == null
            ? '전체'
            : (snap.data ?? const <Affiliation>[])
                  .where((a) => a.id == id)
                  .map((a) => a.name)
                  .firstOrNull;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            item(AppIcons.calendarDays, widget.date),
            if (widget.views != null)
              item(AppIcons.eyeCount, '조회 ${widget.views}'),
            item(
              widget.isPrivate ? AppIcons.lock : AppIcons.globe,
              widget.isPrivate ? '교역자 전용' : '공개',
            ),
            if (name != null) item(AppIcons.usersThree, '소속 $name'),
          ],
        );
      },
    );
  }
}
