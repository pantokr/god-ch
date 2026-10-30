import '../../../core/widgets/app_loader.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/list_style_controller.dart';
import '../../../app/routes.dart';
import '../../../core/format.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/icons.dart';
import '../../../core/widgets/refresh_scope.dart';
import '../../../core/widgets/sort_pad.dart';
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
import 'postit_card.dart' show kPostItEnabled;
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
      builder: (context, affiliation) => RefreshScope(
        builder: (context, generation, refresh) =>
            ViewModelBuilder<PrayerListViewModel>(
              // 소속이 바뀌거나 새로고침하면 기도제목을 새로 구독한다.
              key: ValueKey(
                'board/${me.churchId}/${affiliation?.id}/$generation',
              ),
              create: (context) => PrayerListViewModel(
                AppScope.read(context).prayers
                    .publicFeed(me.churchId, affiliationId: affiliation?.id),
              ),
              builder: (context, vm) => Stack(
                fit: StackFit.expand,
                children: [
                  ListenableBuilder(
                    listenable: style,
                    builder: (context, _) =>
                        kPostItEnabled && style.style == ListStyle.colorful
                        ? FloatingPrayers(
                            prayers: vm.prayers,
                            me: me,
                            count: floating,
                            fullScreen: true,
                          )
                        : _MinimalList(
                            prayers: vm.prayers,
                            me: me,
                            refresh: refresh,
                          ),
                  ),
                  // 떠다니는 카드 화면에서만 오른쪽 위에 둔다 (카드 격자 화면은 목록 위 줄에 있다).
                  if (kPostItEnabled && style.style == ListStyle.colorful)
                    Positioned(right: 8, top: 8, child: refresh),
                  Positioned(
                    right: 16,
                    bottom: 16 + MediaQuery.paddingOf(context).bottom,
                    child: PrayerWriteFab(me: me, affiliation: affiliation),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}

/// 정렬 기준.
enum _PrayerSort {
  latest('최신순'),
  popular('인기순'),
  oldest('오래된순');

  const _PrayerSort(this.label);

  final String label;
}

/// 심플 격자. 위에 일정 · 말씀묵상과 같은 패드(검색 · 정렬 순서)가 있다.
class _MinimalList extends StatefulWidget {
  const _MinimalList({
    required this.prayers,
    required this.me,
    required this.refresh,
  });

  /// 새로고침 버튼 (말씀묵상과 같이 패널 아래 구분선 밑 오른쪽에 둔다).
  final Widget refresh;

  final Stream<List<Prayer>> prayers;
  final Member me;

  @override
  State<_MinimalList> createState() => _MinimalListState();
}

class _MinimalListState extends State<_MinimalList> {
  final _search = TextEditingController();
  String _query = '';
  _PrayerSort _sort = _PrayerSort.latest;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// 검색어(제목 · 내용)에 맞는 글을 정렬 기준대로 돌려준다. 읽어 온 순서는 최신순이다.
  List<Prayer> _apply(List<Prayer> all) {
    final list = [
      for (final p in all)
        if (_query.isEmpty ||
            p.title.toLowerCase().contains(_query) ||
            p.content.toLowerCase().contains(_query))
          p,
    ];
    switch (_sort) {
      case _PrayerSort.latest:
        break;
      case _PrayerSort.popular:
        list.sort((a, b) => b.views.compareTo(a.views));
      case _PrayerSort.oldest:
        return list.reversed.toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // 오른쪽 아래의 기도 요청 버튼에 마지막 줄이 가리지 않게 아래를 비운다.
      padding: const EdgeInsets.only(bottom: 88),
      child: PageFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageTitle(
              gap: PageTitle.panelGap,
              title: '중보기도',
              description: '함께 나누고 싶은 기도제목을 올리고, 서로를 위해 이모티콘으로 응원합니다. 비공개로 올린 글은 작성자와 교역자만 볼 수 있어요.',
            ),
            SortPad(
              header: TextField(
                controller: _search,
                onChanged: (v) =>
                    setState(() => _query = v.trim().toLowerCase()),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: '검색',
                  isDense: true,
                  prefixIcon: const Icon(AppIcons.magnifyingGlass, size: 18),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(AppIcons.x, size: 18),
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
              ),
              groups: [
                PadGroup(label: '정렬 순서', [
                  for (final o in _PrayerSort.values)
                    PadOption(
                      o.label,
                      selected: _sort == o,
                      onTap: () => setState(() => _sort = o),
                    ),
                ]),
              ],
            ),
            const SizedBox(height: 16),
            // 패널 영역과 목록 영역을 가르는 선, 그 아래 목록 윗부분 오른쪽에 새로고침 (말씀묵상과 같다).
            Divider(height: 1, color: context.palette.border),
            Align(alignment: Alignment.centerRight, child: widget.refresh),
            StreamBuilder<List<Prayer>>(
              stream: widget.prayers,
              builder: (context, snap) {
                if (snap.hasError) {
                  return EmptyHint('불러오지 못했습니다\n${snap.error}');
                }
                final all = snap.data;
                if (all == null) {
                  return const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: AppLoader()),
                  );
                }
                final items = _apply(all);
                if (items.isEmpty) {
                  return EmptyHint(all.isEmpty ? '기도제목 없음' : '검색 결과 없음');
                }
                return _Grid(
                  children: [
                    for (final p in items) _Tile(prayer: p, me: widget.me),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 폭이 좁으면 한 줄에 하나, 넉넉하면 두 개씩 놓는 격자. 카드는 모두 같은 크기다.
class _Grid extends StatelessWidget {
  const _Grid({required this.children});

  final List<Widget> children;

  static const _gap = 12.0;

  /// 카드 높이(글자 크기 1배일 때): 제목 2줄 + 날짜 + 내용 4줄 + 수치와 여백.
  static const tileHeight = 252.0;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth >= 360 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: children.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: _gap,
            crossAxisSpacing: _gap,
            mainAxisExtent: tileHeight * scale,
          ),
          itemBuilder: (context, i) => children[i],
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
              // 제목은 한 줄이어도 두 줄 높이를 잡아 카드 안 배치를 맞춘다.
              SizedBox(
                height:
                    16 * 1.3 * 2 * MediaQuery.textScalerOf(context).scale(1),
                child: Text(
                  p.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                fmtDateTime(p.createdAt),
                style: TextStyle(color: palette.muted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  p.content,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: readingStyle(context).copyWith(fontSize: 14),
                ),
              ),
              const SizedBox(height: 8),
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
