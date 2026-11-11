import '../../../core/widgets/app_loader.dart';

import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/format.dart';
import '../../../core/icons.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_inputs.dart';
import '../../../core/widgets/sort_pad.dart';
import '../../../data/models/activity_log.dart';
import '../../../data/models/church.dart';
import '../../home/view/content_widgets.dart';
import '../view_model/activity_log_view_model.dart';

/// 앱 운영자 > 활동 기록: 회원별 접속 · 활동을 최근 순으로 본다.
/// 갈래(계정 · 교회 · 중보기도 · 말씀묵상 · 모임 · 관리)와 검색으로 거르고, 줄을 누르면 그 회원의 기록만 본다.
class ActivityLogPage extends StatelessWidget {
  const ActivityLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ActivityLogViewModel>(
      create: (context) {
        final scope = AppScope.read(context);
        return ActivityLogViewModel(scope.activityLogs, scope.churchRegistry);
      },
      builder: (context, vm) => SingleChildScrollView(
        child: PageFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSearchField(
                inset: true,
                hint: '이름, 종류, 교회 검색',
                onChanged: vm.setQuery,
              ),
              const SizedBox(height: 12),
              SortStrip(
                options: [
                  PadOption(
                    '전체',
                    selected: vm.group == null,
                    onTap: () => vm.setGroup(null),
                  ),
                  for (final g in ActivityGroup.values)
                    PadOption(
                      g.label,
                      selected: vm.group == g,
                      onTap: () => vm.setGroup(g),
                    ),
                ],
              ),
              if (vm.focusUid != null) ...[
                const SizedBox(height: 12),
                _FocusChip(name: vm.focusName, onClear: vm.clearFocus),
              ],
              StreamBuilder<List<Church>>(
                stream: vm.churches,
                builder: (context, churches) =>
                    StreamBuilder<List<ActivityLog>>(
                      stream: vm.logs,
                      builder: (context, snap) {
                        if (snap.hasError) {
                          return EmptyHint(
                            '불러오지 못했습니다${String.fromCharCode(10)}${snap.error}',
                          );
                        }
                        final all = snap.data;
                        if (all == null) {
                          return const Padding(
                            padding: EdgeInsets.all(48),
                            child: Center(child: AppLoader()),
                          );
                        }
                        final names = {
                          for (final c in churches.data ?? const <Church>[])
                            c.id: c.name,
                        };
                        final items = vm.apply(all, names);
                        if (items.isEmpty) {
                          return EmptyHint(
                            all.isEmpty ? '기록 없음' : '해당하는 기록 없음',
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Card(
                              child: Column(
                                children: [
                                  for (var i = 0; i < items.length; i++) ...[
                                    if (i > 0) const Divider(height: 1),
                                    _LogRow(
                                      log: items[i],
                                      churchName:
                                          names[items[i].churchId] ?? '',
                                      onTap: vm.focusUid == null
                                          ? () => vm.focusUser(
                                              items[i].uid,
                                              items[i].userName,
                                            )
                                          : null,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // 가져온 줄이 한도를 다 채웠으면 더 오래된 기록이 있을 수 있다.
                            if (all.length >= vm.limit)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: OutlinedButton(
                                  onPressed: vm.loadMore,
                                  child: const Text('더 보기'),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// 한 회원의 기록만 보고 있다는 표시와 해제 버튼.
class _FocusChip extends StatelessWidget {
  const _FocusChip({required this.name, required this.onClear});

  final String name;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Align(
      alignment: Alignment.centerLeft,
      child: InputChip(
        avatar: Icon(AppIcons.user, size: 16, color: palette.brand),
        label: Text(name.isEmpty ? '이름 없음' : name),
        deleteIcon: const Icon(AppIcons.x, size: 16),
        deleteButtonTooltipMessage: '전체 기록',
        onDeleted: onClear,
      ),
    );
  }
}

/// 기록 한 줄: 갈래 아이콘, 이름과 종류, 교회와 설명, 일시.
class _LogRow extends StatelessWidget {
  const _LogRow({required this.log, required this.churchName, this.onTap});

  final ActivityLog log;
  final String churchName;
  final VoidCallback? onTap;

  static IconData _icon(ActivityGroup g) => switch (g) {
    ActivityGroup.account => AppIcons.user,
    ActivityGroup.church => AppIcons.church,
    ActivityGroup.prayer => AppIcons.handHeart,
    ActivityGroup.devotion => AppIcons.bookOpen,
    ActivityGroup.meeting => AppIcons.usersRound,
    ActivityGroup.manage => AppIcons.shieldCheck,
  };

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final detail = [
      if (churchName.isNotEmpty) churchName,
      if (log.summary.isNotEmpty) log.summary,
    ].join(' · ');
    final who = log.userName.isEmpty ? '이름 없음' : log.userName;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(_icon(log.type.group), size: 20, color: palette.muted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$who · ${log.type.label}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (detail.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: palette.muted, fontSize: 12.5),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              fmtDateTime(log.at),
              style: TextStyle(color: palette.muted, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}
