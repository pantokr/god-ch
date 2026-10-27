import 'package:flutter/material.dart';

import '../../../core/layout/card_grid.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/theme.dart';
import '../../../data/models/member.dart';
import '../../../data/models/prayer.dart';
import 'prayer_card.dart';

/// 제목 줄 + 반응형 카드 그리드. 피드와 내 기도제목이 함께 쓴다.
class PrayerList extends StatelessWidget {
  const PrayerList({
    super.key,
    required this.prayers,
    required this.me,
    required this.title,
    required this.emptyText,
    required this.showReactions,
    required this.onWrite,
  });

  final Stream<List<Prayer>> prayers;
  final Member me;
  final String title;
  final String emptyText;
  final bool showReactions;
  final VoidCallback onWrite;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: PageFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageTitle(
              title: title,
              action: FilledButton.icon(
                onPressed: onWrite,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('기도제목 쓰기'),
              ),
            ),
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
  });

  final Stream<List<Prayer>> prayers;

  /// 목록에 보여줄 글만 거르는 조건. 없으면 전부 보여준다.
  final bool Function(Prayer prayer)? where;
  final Member me;
  final String emptyText;
  final bool showReactions;

  /// 교역자 화면에서 카드에 작성자 이름을 덧붙일 때 쓴다 (uid → 이름).
  final Map<String, String> authorNames;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Prayer>>(
      stream: prayers,
      builder: (context, snap) {
        if (snap.hasError) return Text('불러오지 못했습니다\n${snap.error}');
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final items = where == null
            ? snap.data!
            : snap.data!.where(where!).toList();
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
