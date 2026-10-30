import '../../../core/widgets/app_loader.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/format.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/shadow_switch.dart';
import '../../../core/widgets/sort_pad.dart';
import '../../../data/models/meeting.dart';
import '../../../data/models/member.dart';
import '../../../data/models/permission.dart';
import '../../meetings/view/meetings_page.dart' show MeetingListView;
import '../../meetings/view_model/my_meetings_view_model.dart';
import '../../prayers/view/my_prayers_page.dart';
import '../view_model/my_reflections_view_model.dart';
import 'content_widgets.dart';

/// 내 활동에 모이는 내 글의 종류.
enum MyActivity {
  meeting('일정'),
  prayer('중보기도'),
  devotion('말씀');

  const MyActivity(this.label);

  final String label;
}

/// "내 활동": 내 일정(참여하거나 이끄는 모임), 내가 쓴 기도제목, 내가 남긴 묵상 모음.
class MyActivityPage extends StatefulWidget {
  const MyActivityPage({super.key, required this.me});

  final Member me;

  @override
  State<MyActivityPage> createState() => _MyActivityPageState();
}

class _MyActivityPageState extends State<MyActivityPage> {
  MyActivity _current = MyActivity.meeting;

  @override
  Widget build(BuildContext context) {
    // 제목과 스위치는 목록 안쪽 맨 위에 놓여 목록과 함께 스크롤된다.
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageTitle(
          gap: PageTitle.panelGap,
          title: '내 활동',
          description:
              '내가 참여하는 일정, 쓴 기도제목, 남긴 묵상을 한곳에 모아 봅니다. 아래 스위치로 종류를 바꿔 볼 수 있어요.',
        ),
        const SizedBox(height: 16),
        ShadowSwitch<MyActivity>(
          values: MyActivity.values,
          selected: _current,
          onChanged: (v) => setState(() => _current = v),
          labelOf: (a) => a.label,
        ),
        const SizedBox(height: 16),
      ],
    );
    return switch (_current) {
      MyActivity.meeting => _MyMeetings(
        key: const ValueKey('mine/meeting'),
        me: widget.me,
        header: header,
      ),
      MyActivity.prayer => MyPrayersPage(
        key: const ValueKey('mine/prayer'),
        me: widget.me,
        header: header,
      ),
      MyActivity.devotion => _MyReflections(
        key: const ValueKey('mine/devotion'),
        me: widget.me,
        header: header,
      ),
    };
  }
}

/// 내가 참여하거나 이끄는 모임 목록. 누르면 모임 상세가 열린다.
class _MyMeetings extends StatelessWidget {
  const _MyMeetings({super.key, required this.me, required this.header});

  final Member me;

  /// 제목과 스위치. 목록과 함께 스크롤된다.
  final Widget header;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<MyMeetingsViewModel>(
      create: (context) => MyMeetingsViewModel(
        AppScope.read(context).meetings,
        me.churchId,
        me.id,
      ),
      builder: (context, vm) => SingleChildScrollView(
        child: PageFrame(
          header: header,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SortPad(
                groups: [
                  PadGroup(label: '보기', [
                    for (final v in MyMeetingView.values)
                      PadOption(
                        v.label,
                        selected: vm.view == v,
                        onTap: () => vm.setView(v),
                      ),
                  ]),
                ],
              ),
              const SizedBox(height: 16),
              // 패널 영역과 목록 영역을 가르는 선 (일정 탭과 같다).
              Divider(height: 1, color: context.palette.border),
              const SizedBox(height: 12),
              StreamBuilder<List<Meeting>>(
                stream: vm.items,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Text('불러오지 못했습니다\n${snap.error}');
                  }
                  if (!snap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: AppLoader()),
                    );
                  }
                  final items = vm.apply(snap.data!);
                  if (items.isEmpty) return const EmptyHint('일정 없음');
                  return MeetingListView(
                    meetings: items,
                    me: me,
                    onLike: me.isOperatorView
                        ? null
                        : (m, liked) => vm.setLike(m.id, liked: liked),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 내가 말씀묵상에 남긴 글 목록. 카드에는 본문 없이 내 묵상만 담고, 누르면 본문과 묵상이 함께 열린다.
class _MyReflections extends StatelessWidget {
  const _MyReflections({super.key, required this.me, required this.header});

  final Member me;

  /// 제목과 스위치. 목록과 함께 스크롤된다.
  final Widget header;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ViewModelBuilder<MyReflectionsViewModel>(
      create: (context) {
        final scope = AppScope.read(context);
        return MyReflectionsViewModel(
          scope.contents,
          scope.reflections,
          me.churchId,
          includePrivate: me.can(Permission.devotionViewPrivate),
        );
      },
      builder: (context, vm) => SingleChildScrollView(
        child: PageFrame(
          header: header,
          child: StreamBuilder<List<MyReflection>>(
            stream: vm.items,
            builder: (context, snap) {
              if (snap.hasError) return Text('불러오지 못했습니다\n${snap.error}');
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: AppLoader()),
                );
              }
              final items = snap.data!;
              if (items.isEmpty) return const EmptyHint('쓴 묵상 없음');
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final m in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => context.push(
                            Routes.devotion(me.churchId, m.devotion.id),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.reflection.text,
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (m.reflection.updatedAt != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    fmtDateTime(m.reflection.updatedAt!),
                                    style: TextStyle(
                                      color: palette.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
