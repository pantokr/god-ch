import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/church_features.dart';
import '../../../data/models/department.dart';
import '../../../data/models/member.dart';
import '../../../data/models/page_layout.dart';
import '../view_model/department_choice.dart';
import '../view_model/group_access_view_model.dart';
import 'department_select.dart';
import 'church_page_view.dart';
import 'content_widgets.dart';
import 'page_icons.dart';

/// 하단 탭 "홈" · "기도" · "말씀": 그룹에 속한 페이지들을 칩으로 고르고, 고른 페이지의 레이아웃을 바로 보여준다.
/// 페이지가 하나뿐이면 칩 없이 그 페이지만 보인다.
///
/// 기도 · 말씀은 교역자가 부서별로 켜고 끈다 ([ChurchFeatures]).
/// - 소속 부서가 모두 꺼져 있으면 서비스가 허용되지 않았다는 안내만 보인다.
/// - 소속 부서 중 쓸 수 있는 부서가 여럿이면 위쪽 탭(서랍 버튼 줄) 오른쪽에서 부서를 고른다 ([DepartmentSelect]).
class GroupHubPage extends StatefulWidget {
  const GroupHubPage({
    super.key,
    required this.group,
    required this.pages,
    required this.me,
    required this.choice,
    this.department,
  });

  final PageGroup group;

  /// 교회의 모든 페이지. 이 중 [group]에 속한 것만 보인다.
  final List<PageConfig> pages;
  final Member me;

  /// 지금 고른 부서 (위쪽 탭의 부서 선택과 함께 쓴다).
  final DepartmentChoice choice;
  final Department? department;

  @override
  State<GroupHubPage> createState() => _GroupHubPageState();
}

class _GroupHubPageState extends State<GroupHubPage> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    if (widget.group == PageGroup.home) {
      return _content(widget.department);
    }
    // 앱 개발자는 교회를 고칠 수 있어도 기도제목 내용은 볼 수 없다.
    if (widget.me.isOperatorView && widget.group == PageGroup.prayer) {
      return const _OperatorNotice();
    }
    return ViewModelBuilder<GroupAccessViewModel>(
      key: ValueKey('access/${widget.me.churchId}'),
      create: (context) => GroupAccessViewModel(
        AppScope.read(context).departments,
        widget.me.churchId,
      ),
      builder: (context, vm) => StreamBuilder<List<Department>>(
        stream: vm.departments,
        builder: (context, depts) => StreamBuilder<ChurchFeatures>(
          stream: vm.features,
          builder: (context, feat) {
            if (!depts.hasData || !feat.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final access = feat.data!.accessFor(
              widget.group,
              widget.me,
              depts.data!,
            );
            if (access.blocked) return _NotAllowed(group: widget.group);
            return _withDepartment(access);
          },
        ),
      ),
    );
  }

  /// 고른 부서의 내용을 보여준다. 부서는 위쪽 탭(서랍 버튼 줄) 오른쪽에서 고르고, 소속 부서가 없으면 교회 전체다.
  Widget _withDepartment(TabAccess access) => ListenableBuilder(
    listenable: widget.choice,
    builder: (context, _) =>
        _content(chosenDepartment(access, widget.choice) ?? widget.department),
  );

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      avatar: icon == null ? null : Icon(icon, size: 18),
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    ),
  );

  Widget _chipRow(List<Widget> chips) => SizedBox(
    height: 52,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: chips,
    ),
  );

  Widget _content(Department? department) {
    final items = [
      for (final p in widget.pages)
        if (p.group == widget.group) p,
    ];
    if (items.isEmpty) {
      return PageFrame(
        child: EmptyHint(widget.me.isStaff ? '페이지 편집에서 추가' : '준비 중'),
      );
    }
    // 홈은 탭으로 나누지 않고 페이지들을 한 화면에 위에서 아래로 이어 붙인다 (순서는 페이지 편집에서 정한다).
    if (widget.group == PageGroup.home) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final p in items)
                ChurchPageBody(
                  key: ValueKey('home/${p.id}/${department?.id}'),
                  page: p,
                  me: widget.me,
                  department: department,
                ),
            ],
          ),
        ),
      );
    }
    final page = items.firstWhere(
      (p) => p.id == _selected,
      orElse: () => items.first,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 한 그룹에 페이지가 여럿이면 칩으로 고른다.
        if (items.length > 1)
          _chipRow([
            for (final p in items)
              _chip(
                label: p.title,
                icon: pageIconOf(p.icon).outlined,
                selected: p.id == page.id,
                onTap: () => setState(() => _selected = p.id),
              ),
          ]),
        Expanded(
          child: ChurchPageView(
            key: ValueKey('hub/${page.id}/${department?.id}'),
            page: page,
            me: widget.me,
            department: department,
            // 기도 · 말씀은 페이지 제목도 카드도 없이 화면 전체를 쓴다.
            fullScreen: true,
          ),
        ),
      ],
    );
  }
}

/// 소속 부서에서 이 탭이 꺼져 있을 때의 안내.
class _NotAllowed extends StatelessWidget {
  const _NotAllowed({required this.group});

  final PageGroup group;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 40, color: palette.muted),
            const SizedBox(height: 16),
            Text(
              '본 서비스가 허용되지 않았습니다',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '소속 부서에서 ${group.label} 서비스를 사용할 수 없습니다.\n담당 교역자에게 문의해 주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// 앱 개발자에게 기도 탭 대신 보이는 안내.
class _OperatorNotice extends StatelessWidget {
  const _OperatorNotice();

  @override
  Widget build(BuildContext context) => Center(
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
