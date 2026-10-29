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
import '../../../data/models/member.dart';
import '../../../data/models/prayer.dart';
import '../../../data/models/reaction.dart';
import '../../home/view/content_widgets.dart';
import '../view_model/prayer_list_view_model.dart';
import 'floating_prayers.dart';
import 'prayer_write_fab.dart';

/// 기도제목: 교회의 공개 기도제목.
/// - 알록달록: 화면 가득 포스트잇 카드가 떠다닌다 (배경은 바깥 틀이 깐다).
/// - 심플: 글 중심 목록. 줄마다 제목과 내용 미리보기가 있고 오른쪽 가장자리에 조회수와 응원 수가 보인다.
/// 어느 쪽이든 누르면 기도제목 상세가 열린다. 기도 요청 버튼은 오른쪽 아래에 떠 있다.
class PrayerBoardPage extends StatelessWidget {
  const PrayerBoardPage({super.key, required this.me});

  final Member me;

  /// 한꺼번에 떠다니는 카드 수.
  static const floating = 4;

  @override
  Widget build(BuildContext context) {
    // 앱 개발자는 교회를 고칠 수 있어도 기도제목 내용은 볼 수 없다.
    if (me.isOperatorView) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            '앱 개발자는 기도제목을 볼 수 없습니다',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.palette.muted),
          ),
        ),
      );
    }
    final style = AppScope.read(context).listStyle;
    return ViewModelBuilder<PrayerListViewModel>(
      key: ValueKey('board/${me.churchId}'),
      create: (context) => PrayerListViewModel(
        AppScope.read(context).prayers.publicFeed(me.churchId),
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
          Positioned(right: 16, bottom: 16, child: PrayerWriteFab(me: me)),
        ],
      ),
    );
  }
}

/// 심플 목록.
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
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < items.length; i++)
                      _Row(
                        prayer: items[i],
                        me: me,
                        last: i == items.length - 1,
                      ),
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

class _Row extends StatelessWidget {
  const _Row({required this.prayer, required this.me, required this.last});

  final Prayer prayer;
  final Member me;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final p = prayer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => context.push(Routes.prayer(me.churchId, p.id), extra: p),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            fmtDate(p.createdAt),
                            style: TextStyle(
                              color: palette.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        p.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: readingStyle(context).copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _Stats(prayer: p, me: me),
              ],
            ),
          ),
        ),
        if (!last) Divider(height: 1, color: palette.border),
      ],
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
