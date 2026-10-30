import '../../../core/widgets/app_loader.dart';

import 'package:flutter/material.dart';

import '../../../core/layout/card_grid.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/theme.dart';
import '../../../data/models/member.dart';
import '../../../data/models/prayer.dart';
import 'postit_card.dart';
import 'prayer_card.dart';

/// 반응형 카드 그리드. 내 기도제목이 쓴다 (카드를 누르면 상세에서 조회 · 수정).
class PrayerList extends StatelessWidget {
  const PrayerList({
    super.key,
    required this.prayers,
    required this.me,
    required this.emptyText,
    required this.showReactions,
    this.header,
  });

  final Stream<List<Prayer>> prayers;
  final Member me;
  final String emptyText;
  final bool showReactions;

  /// 목록 위에 함께 스크롤되는 머리 (내 활동의 제목과 스위치).
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: PageFrame(
        header: header,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PrayerGrid(
              prayers: prayers,
              me: me,
              emptyText: emptyText,
              showReactions: showReactions,
            ),
          ],
        ),
      ),
    );
  }
}

/// 기도제목 스트림을 카드 그리드로 그린다. 로딩·오류·빈 상태를 함께 처리한다.
class PrayerGrid extends StatelessWidget {
  const PrayerGrid({
    super.key,
    required this.prayers,
    required this.me,
    required this.emptyText,
    this.showReactions = false,
    this.authorNames = const {},
    this.where,
    this.flat = false,
  });

  final Stream<List<Prayer>> prayers;

  /// 목록에 보여줄 글만 거르는 조건. 없으면 전부 보여준다.
  final bool Function(Prayer prayer)? where;
  final Member me;
  final String emptyText;
  final bool showReactions;

  /// 교역자 화면에서 카드에 작성자 이름을 덧붙일 때 쓴다 (uid → 이름).
  final Map<String, String> authorNames;

  /// 카드 대신 포스트잇 게시판으로 그린다 (화면 전체를 쓰는 기도 화면).
  final bool flat;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Prayer>>(
      stream: prayers,
      builder: (context, snap) {
        if (snap.hasError) return Text('불러오지 못했습니다\n${snap.error}');
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: AppLoader()),
          );
        }
        final items = where == null
            ? snap.data!
            : snap.data!.where(where!).toList();
        if (items.isEmpty && flat) {
          return Padding(
            padding: const EdgeInsets.all(48),
            child: Center(
              child: Text(
                emptyText,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.palette.muted),
              ),
            ),
          );
        }
        if (items.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Center(
                child: Text(
                  emptyText,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.palette.muted),
                ),
              ),
            ),
          );
        }
        // 화면 전체를 쓰는 기도 화면은 포스트잇을 붙여 놓은 게시판으로 보여준다.
        if (flat) {
          return PostItWall(
            prayers: items,
            me: me,
            showReactions: showReactions,
            authorNames: authorNames,
          );
        }
        return CardGrid(
          children: [
            for (final p in items)
              PrayerCard(
                prayer: p,
                me: me,
                showReactions: showReactions && p.isPublic,
                subtitle: authorNames.isEmpty
                    ? null
                    : (authorNames[p.authorId] ?? '알 수 없음'),
              ),
          ],
        );
      },
    );
  }
}
