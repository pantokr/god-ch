import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/list_style_controller.dart';
import '../../../app/routes.dart';
import '../../../core/format.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/stat_icons.dart';
import '../../../data/models/church_features.dart';
import '../../../data/models/member.dart';
import '../../../data/models/prayer.dart';
import '../../../data/models/reaction.dart';
import '../../home/view/content_widgets.dart';
import '../../home/view/feature_gate.dart';
import '../../home/view_model/affiliation_choice.dart';
import '../view_model/prayer_list_view_model.dart';
import 'floating_prayers.dart';
import 'prayer_write_fab.dart';

/// 기도제목: 고른 소속(속한 소속이 없으면 교회 전체)의 공개 기도제목.
/// - 알록달록: 화면 가득 포스트잇 카드가 떠다닌다 (배경은 바깥 틀이 깐다).
/// - 심플: 카드 격자. 카드마다 제목과 내용 미리보기가 있고 아래에 조회수와 응원 수가 보인다.
/// 어느 쪽이든 누르면 기도제목 상세가 열린다. 기도 요청 버튼은 오른쪽 아래에 떠 있다.
class PrayerBoardPage extends StatelessWidget {
  const PrayerBoardPage({super.key, required this.me, required this.choice});

  final Member me;
  final AffiliationChoice choice;

  /// 한꺼번에 떠다니는 카드 수.
  static const floating = 4;

  @override
  Widget build(BuildContext context) {
    final style = AppScope.read(context).listStyle;
    return FeatureGate(
      feature: PageFeature.prayer,
      me: me,
      choice: choice,
      builder: (context, affiliation) => ViewModelBuilder<PrayerListViewModel>(
        // 소속이 바뀌면 그 소속의 기도제목을 새로 구독한다.
        key: ValueKey('board/${me.churchId}/${affiliation?.id}'),
        create: (context) => PrayerListViewModel(
          AppScope.read(context).prayers
              .publicFeed(me.churchId, affiliationId: affiliation?.id),
        ),
        builder: (context, vm) => Stack(
          fit: StackFit.expand,
          children: [
            ListenableBuilder(
              listenable: style,
              builder: (context, _) => style.style == ListStyle.colorful
                  ? FloatingPrayers(
                      prayers: vm.prayers,
                      me: me,
                      count: floating,
                      fullScreen: true,
                    )
                  : _MinimalList(prayers: vm.prayers, me: me),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: PrayerWriteFab(me: me, affiliation: affiliation),
            ),
          ],
        ),
      ),
    );
  }
}

/// 심플 격자.
class _MinimalList extends StatelessWidget {
  const _MinimalList({required this.prayers, required this.me});

  final Stream<List<Prayer>> prayers;
  final Member me;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // 오른쪽 아래의 기도 요청 버튼에 마지막 줄이 가리지 않게 아래를 비운다.
      padding: const EdgeInsets.only(bottom: 88),
      child: PageFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageTitle(title: '기도제목'),
            StreamBuilder<List<Prayer>>(
              stream: prayers,
              builder: (context, snap) {
                if (snap.hasError) {
                  return EmptyHint('불러오지 못했습니다\n${snap.error}');
                }
                final items = snap.data;
                if (items == null) {
                  return const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (items.isEmpty) return const EmptyHint('기도제목 없음');
                return _Grid(
                  children: [for (final p in items) _Tile(prayer: p, me: me)],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 폭이 좁으면 한 줄에 하나, 넉넉하면 두 개씩 놓는 격자.
class _Grid extends StatelessWidget {
  const _Grid({required this.children});

  final List<Widget> children;

  static const _gap = 12.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth >= 360 ? 2 : 1;
        final width = (box.maxWidth - _gap * (cols - 1)) / cols;
        return Wrap(
          spacing: _gap,
          runSpacing: _gap,
          children: [
            for (final c in children) SizedBox(width: width, child: c),
          ],
        );
      },
    );
  }
}

/// 격자의 기도제목 카드 하나: 제목 · 날짜 · 내용 미리보기, 아래에 조회수와 응원 수.
class _Tile extends StatelessWidget {
  const _Tile({required this.prayer, required this.me});

  final Prayer prayer;
  final Member me;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final p = prayer;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(Routes.prayer(me.churchId, p.id), extra: p),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                fmtDate(p.createdAt),
                style: TextStyle(color: palette.muted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                p.content,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: readingStyle(context).copyWith(fontSize: 14),
              ),
              const SizedBox(height: 12),
              _Stats(prayer: p, me: me),
            ],
          ),
        ),
      ),
    );
  }
}

/// 조회수와 응원 수 (이모티콘 응원의 합). 응원 수는 저장소에서 실시간으로 읽는다.
class _Stats extends StatelessWidget {
  const _Stats({required this.prayer, required this.me});

  final Prayer prayer;
  final Member me;

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.read(context).prayers;
    return StreamBuilder<ReactionSummary>(
      stream: repo.reactions(me.churchId, prayer.id),
      builder: (context, snap) {
        final r = snap.data ?? ReactionSummary.empty;
        return StatIcons(
          views: prayer.views,
          likes: r.total,
          liked: r.mine.isNotEmpty,
        );
      },
    );
  }
}
