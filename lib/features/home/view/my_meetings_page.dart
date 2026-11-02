import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/shadow_switch.dart';
import '../../../core/widgets/sort_pad.dart';
import '../../../data/models/meeting.dart';
import '../../../data/models/member.dart';
import '../../meetings/view/meetings_page.dart' show MeetingListView;
import '../../meetings/view_model/meetings_view_model.dart' show MeetingSort;
import '../../meetings/view_model/my_meetings_view_model.dart';
import 'content_widgets.dart';

/// 내 활동의 "자세히 보기": 참여 예정 · 관심 일정 · 완료 일정을 스위치로 나누어 본다.
/// 스위치 아래는 일정 탭과 같은 정렬 줄 · 목록이다.
class MyMeetingsPage extends StatelessWidget {
  const MyMeetingsPage({super.key, required this.me});

  final Member me;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BleedBox(
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: ShadowSwitch<MyMeetingView>(
                        values: MyMeetingView.values,
                        selected: vm.view,
                        onChanged: vm.setView,
                        labelOf: (v) => v.label,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SortStrip(
                      options: [
                        for (final s in MeetingSort.values)
                          PadOption(
                            s.label,
                            selected: vm.sort == s,
                            onTap: () => vm.setSort(s),
                          ),
                      ],
                    ),
                    SortBody(
                      child: StreamBuilder<List<Meeting>>(
                        stream: vm.items,
                        builder: (context, snap) {
                          if (snap.hasError) {
                            return EmptyHint(
                              '불러오지 못했습니다${String.fromCharCode(10)}${snap.error}',
                            );
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
