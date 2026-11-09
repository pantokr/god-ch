import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/icons.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/role_chips.dart';
import '../../../data/models/affiliation.dart';

/// 작성자 줄의 내용: 아바타와 이름 (눌러서 프로필을 연다). 중보기도 · 말씀묵상 · 모임 일정이 같은 모양을 쓴다.
class PostAuthor extends StatelessWidget {
  const PostAuthor({super.key, required this.avatar, required this.name});

  /// 눌러서 프로필을 여는 아바타.
  final Widget avatar;

  /// 눌러서 프로필을 여는 이름.
  final Widget name;

  /// 이름 글자 모양.
  static TextStyle nameStyle(BuildContext context) =>
      TextStyle(color: context.palette.ink, fontWeight: FontWeight.w600);

  /// 아바타 크기.
  static const avatarRadius = 12.0;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      avatar,
      const SizedBox(width: 8),
      Flexible(child: name),
    ],
  );
}

/// 글 상세의 정보 줄 (중보기도 · 말씀묵상 · 모임 일정이 같은 모양을 쓴다):
/// 작성자 · 작성일 · 조회수 · 공개 여부(공개 / 교역자 전용) · 소속(없으면 "전체")을 한 줄에 하나씩 아래로 쌓는다 (모임 일정 상세의 정보 줄과 같은 모양).
class PostMeta extends StatefulWidget {
  const PostMeta({
    super.key,
    required this.churchId,
    required this.date,
    required this.isPrivate,
    this.affiliationId,
    this.affiliationIds,
    this.views,
    this.color,
    this.showScope = true,
    this.showPrivacy = true,
    this.author,
  });

  /// 작성자 줄(아바타 · 이름). 없으면 줄을 두지 않는다 (작성자를 숨기는 글).
  final Widget? author;

  /// false이면 공개 여부(공개 · 교역자 전용) 줄만 뺀다 (모임 일정은 공개 범위(소속)만 있다).
  final bool showPrivacy;

  final String churchId;

  /// 날짜와 시각을 이미 다듬은 문구.
  final String date;
  final bool isPrivate;

  /// 글의 소속. 없으면 "전체".
  final String? affiliationId;

  /// 공개 범위가 여러 소속일 때(모임): 이 값이 있으면 [affiliationId] 대신 쓴다. 비어 있으면 전체다.
  final List<String>? affiliationIds;

  /// false이면 공개 여부와 소속 줄을 빼고 날짜 · 조회수만 보인다 (모임 일정처럼 공개 범위가 없는 글).
  final bool showScope;

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
    Widget item(IconData icon, String label, Object value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          SizedBox(
            // 글씨가 커져도 라벨이 값에 맞닿지 않게 칸 너비가 글씨 배율을 따르고, 사이에 여백을 둔다.
            width: MediaQuery.textScalerOf(context).scale(72) + 8,
            child: Text(label, style: TextStyle(color: palette.muted)),
          ),
          Expanded(
            child: value is Widget
                ? Align(alignment: Alignment.centerLeft, child: value)
                : Text('$value', style: TextStyle(color: textColor)),
          ),
        ],
      ),
    );
    // 공개 범위: 소속 여럿(모임)이거나 하나. 하나도 없으면 전체다.
    final ids =
        widget.affiliationIds ??
        [if (widget.affiliationId != null) widget.affiliationId!];
    return StreamBuilder<List<Affiliation>>(
      stream: ids.isEmpty ? null : _affiliations,
      builder: (context, snap) {
        final name = ids.isEmpty
            ? '전체'
            : [
                for (final a in snap.data ?? const <Affiliation>[])
                  if (ids.contains(a.id)) a.name,
              ].join(', ');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.author != null)
              item(AppIcons.user, '작성자', widget.author!),
            if (widget.date.isNotEmpty)
              item(AppIcons.calendarDays, '작성일', widget.date),
            if (widget.views != null)
              item(AppIcons.eyeCount, '조회수', '${widget.views}회'),
            if (widget.showScope && widget.showPrivacy)
              item(
                widget.isPrivate ? AppIcons.lock : AppIcons.globe,
                '공개 여부',
                widget.isPrivate ? '교역자 전용' : '공개',
              ),
            if (widget.showScope && widget.affiliationIds != null)
              // 모임 일정: 공개 범위를 소속 칩으로 보이고 차례로 떠오르게 한다.
              item(
                AppIcons.usersThree,
                '공개 범위',
                AffiliationChips([
                  for (final a in snap.data ?? const <Affiliation>[])
                    if (ids.contains(a.id)) a.name,
                ]),
              )
            else if (widget.showScope && name.isNotEmpty)
              item(AppIcons.usersThree, '공개 범위', name),
          ],
        );
      },
    );
  }
}

/// 글 상세의 작성 정보 카드 (중보기도 · 말씀묵상 · 모임 일정이 같은 틀을 쓴다):
/// 정보 줄([meta])이 한 카드, 반응 · 좋아요([footer])가 그 아래 별개의 카드다.
/// 정보 줄과 반응은 글의 종류마다 다르지만 카드 틀과 간격은 같다.
class PostInfoCard extends StatelessWidget {
  const PostInfoCard({
    super.key,
    required this.meta,
    this.footer,
    this.shape,
    this.color,
  });

  /// 카드 바탕색 (개인 설정의 카드 색). 없으면 카드 기본색이다.
  final Color? color;

  final Widget meta;

  /// 반응 · 좋아요처럼 누르는 것. 없으면 카드를 두지 않는다.
  final Widget? footer;
  final ShapeBorder? shape;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          shape: shape,
          color: color,
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: meta,
          ),
        ),
        if (footer != null) ...[
          const SizedBox(height: 12),
          Card(
            shape: shape,
            color: color,
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Align(alignment: Alignment.centerLeft, child: footer),
            ),
          ),
        ],
      ],
    );
  }
}
