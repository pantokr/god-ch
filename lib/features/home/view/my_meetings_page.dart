import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../core/theme.dart';
import '../../../app/routes.dart';
import '../../../data/models/permission.dart';
import '../../../core/icons.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/shadow_switch.dart';
import '../../../core/widgets/list_style_toggle.dart';
import '../../../core/widgets/sort_pad.dart';
import '../../../data/models/meeting.dart';
import '../../../data/models/member.dart';
import '../../meetings/view/meetings_page.dart' show MeetingListView;
import '../../meetings/view_model/meetings_view_model.dart' show MeetingSort;
import '../../meetings/view_model/my_meetings_view_model.dart';
import '../../meetings/view_model/all_meetings_view_model.dart';
import 'content_widgets.dart';

/// 내 일정 관리: 참여 예정 · 관심 일정 · 참여 완료는 스위치 한 묶음이고, 내가 만든 일정은 화면 위의 바로가기 버튼으로 들어간다
/// (일정을 만드는 권한이 있는 교역자 · 교회 관리자에게만 보인다).
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
              // 바로가기 카드: 상단 탭 바로 아래, 목록 영역과 떨어진 별도 카드다.
              // 만들기 버튼이 아니라 이동하는 줄이라 이름과 > 만 있고, 카드 전체가 눌리며 키가 크다.
              // 일정을 만드는 교역자 · 교회 관리자만 "전체 일정 조회" 화면으로 이동한다.
              if (me.can(Permission.meetingManage))
                Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => context.go(
                      Routes.section(me.churchId, ChurchSection.allMeetings),
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 72),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '전체 일정 조회',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Icon(
                              AppIcons.caretRight,
                              color: context.palette.muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              BleedBox(
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 참여 예정 · 관심 일정 · 참여 완료 한 묶음.
                    Center(
                      child: ShadowSwitch<MyMeetingView>(
                        values: const [
                          MyMeetingView.upcoming,
                          MyMeetingView.liked,
                          MyMeetingView.attended,
                        ],
                        selected: vm.view,
                        onChanged: vm.setView,
                        labelOf: (v) => v.label,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SortStrip(
                      viewToggle: const ListStyleToggle(),
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

/// 전체 일정 조회 (일정을 만드는 교역자 · 교회 관리자): 내 일정 관리와 다른 화면이다.
/// 모든 일정을 제목 · 작성자(모임장)로 검색하고, 범위(전체 · 내가 만든 일정)로 거른다.
class AllMeetingsPage extends StatelessWidget {
  const AllMeetingsPage({super.key, required this.me});

  final Member me;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<AllMeetingsViewModel>(
      create: (context) => AllMeetingsViewModel(
        AppScope.read(context).meetings,
        me.churchId,
        me.id,
      ),
      builder: (context, vm) => SingleChildScrollView(
        child: PageFrame(
          child: BleedBox(
            padding: const EdgeInsets.only(top: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AllMeetingsSearch(vm: vm),
                const SizedBox(height: 16),
                // 범위: 전체 일정 · 내가 만든 일정.
                Center(
                  child: ShadowSwitch<MeetingOwner>(
                    values: MeetingOwner.values,
                    selected: vm.owner,
                    onChanged: vm.setOwner,
                    labelOf: (v) => v.label,
                  ),
                ),
                const SizedBox(height: 16),
                SortStrip(
                  viewToggle: const ListStyleToggle(),
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
                      if (items.isEmpty) {
                        return EmptyHint(
                          vm.query.isEmpty ? '일정 없음' : '검색 결과 없음',
                        );
                      }
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
        ),
      ),
    );
  }
}

/// 전체 일정 조회의 검색창: 제목과 작성자(모임장)로 찾는다.
class _AllMeetingsSearch extends StatefulWidget {
  const _AllMeetingsSearch({required this.vm});

  final AllMeetingsViewModel vm;

  @override
  State<_AllMeetingsSearch> createState() => _AllMeetingsSearchState();
}

class _AllMeetingsSearchState extends State<_AllMeetingsSearch> {
  late final _search = TextEditingController(text: widget.vm.query);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    return PadSearchField(
      child: TextField(
        controller: _search,
        onChanged: vm.setQuery,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: '제목 · 작성자 검색',
          isDense: true,
          suffixIcon: vm.query.isEmpty
              ? const Icon(AppIcons.magnifyingGlass, size: 18)
              : IconButton(
                  icon: const Icon(AppIcons.x, size: 18),
                  onPressed: () {
                    _search.clear();
                    vm.setQuery('');
                  },
                ),
        ),
      ),
    );
  }
}
