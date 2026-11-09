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
import '../../../data/models/member.dart';
import '../../../data/models/membership_event.dart';
import '../../home/view/content_widgets.dart';
import '../view_model/membership_log_view_model.dart';

/// 입장 · 탈퇴 기록 (교회 관리자): 누가 언제 입장하고 탈퇴(추방)했는지 최근 순으로 본다.
/// 검색은 이름 · 아이디로, 범위는 전체 · 입장 · 탈퇴 · 추방으로 고른다.
class MembershipLogPage extends StatelessWidget {
  const MembershipLogPage({super.key, required this.me});

  final Member me;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<MembershipLogViewModel>(
      key: ValueKey('membership-log/${me.churchId}'),
      create: (context) =>
          MembershipLogViewModel(AppScope.read(context).members, me),
      builder: (context, vm) => SingleChildScrollView(
        child: PageFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSearchField(
                inset: true,
                hint: '이름, 아이디 검색',
                onChanged: vm.setQuery,
              ),
              const SizedBox(height: 12),
              SortStrip(
                options: [
                  for (final f in MembershipLogFilter.values)
                    PadOption(
                      f.label,
                      selected: vm.filter == f,
                      onTap: () => vm.setFilter(f),
                    ),
                ],
              ),
              StreamBuilder<List<MembershipEvent>>(
                stream: vm.events,
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
                  final items = vm.apply(all);
                  if (items.isEmpty) {
                    return EmptyHint(all.isEmpty ? '기록 없음' : '해당하는 기록 없음');
                  }
                  return Card(
                    child: Column(
                      children: [
                        for (var i = 0; i < items.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          _EventRow(event: items[i]),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// 기록 한 줄: 종류 표시, 이름(아이디), 일시.
class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});

  final MembershipEvent event;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final error = Theme.of(context).colorScheme.error;
    final (icon, color) = switch (event.kind) {
      MembershipEventKind.joined => (AppIcons.userPlus, palette.brand),
      MembershipEventKind.requested => (AppIcons.userPlus, palette.muted),
      MembershipEventKind.left => (AppIcons.signOut, palette.muted),
      MembershipEventKind.removed => (AppIcons.signOut, error),
    };
    final who = event.loginId.isEmpty
        ? event.name
        : '${event.name}  (${event.loginId})';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  who,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  fmtDateTime(event.at),
                  style: TextStyle(color: palette.muted, fontSize: 12.5),
                ),
              ],
            ),
          ),
          Text(
            event.kind.label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
