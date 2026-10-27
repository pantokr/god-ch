import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/church_features.dart';
import '../../../data/models/department.dart';
import '../../../data/models/member.dart';
import '../../../data/models/page_layout.dart';
import '../view_model/group_access_view_model.dart';
import 'church_page_view.dart';
import 'content_widgets.dart';
import 'page_icons.dart';

/// 하단 탭 "홈" · "기도" · "말씀": 그룹에 속한 페이지들을 칩으로 고르고, 고른 페이지의 레이아웃을 바로 보여준다.
/// 페이지가 하나뿐이면 칩 없이 그 페이지만 보인다.
///
/// 기도 · 말씀은 교역자가 부서별로 켜고 끈다 ([ChurchFeatures]).
/// - 소속 부서가 모두 꺼져 있으면 서비스가 허용되지 않았다는 안내만 보인다.
/// - 쓸 수 있는 부서가 여럿이면 기도 탭에서 부서를 골라 그 부서의 기도제목을 본다.
class GroupHubPage extends StatefulWidget {
  const GroupHubPage({
    super.key,
    required this.group,
    required this.pages,
    required this.me,
    this.department,
  });

  final PageGroup group;

  /// 교회의 모든 페이지. 이 중 [group]에 속한 것만 보인다.
  final List<PageConfig> pages;
  final Member me;
  final Department? department;

  @override
  State<GroupHubPage> createState() => _GroupHubPageState();
}

class _GroupHubPageState extends State<GroupHubPage> {
  String? _selected;

  /// 고른 부서 ID. null이면 처음 선택지(교인) 또는 교회 전체(교역자).
  String? _deptId;

  @override
  Widget build(BuildContext context) {
    if (widget.group == PageGroup.home) {
      return _content(widget.department, const []);
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

  /// 부서 선택(기도 탭만)을 붙여 페이지 내용을 보여준다.
  Widget _withDepartment(TabAccess access) {
    // 기도제목은 부서별로 나뉘므로 기도 탭에서만 부서를 고른다. 말씀은 허용 여부만 가린다.
    final scoped =
        widget.group == PageGroup.prayer && access.options.isNotEmpty;
    if (!scoped) return _content(widget.department, const []);

    final staff = widget.me.isStaff;
    final options = access.options;
    // 교인은 늘 부서 하나가 골라져 있고, 교역자는 "전체"(교회 전체)도 고를 수 있다.
    final chosen = options.where((d) => d.id == _deptId).firstOrNull;
    final department = staff ? chosen : (chosen ?? options.first);
    final chips = options.length > 1 || staff
        ? <Widget>[
            if (staff)
              _chip(
                label: '전체',
                selected: department == null,
                onTap: () => setState(() => _deptId = null),
              ),
            for (final d in options)
              _chip(
                label: d.name,
                selected: department?.id == d.id,
                onTap: () => setState(() => _deptId = d.id),
              ),
          ]
        : const <Widget>[];
    return _content(department ?? widget.department, chips);
  }

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

  Widget _content(Department? department, List<Widget> departmentChips) {
    final items = [
      for (final p in widget.pages)
        if (p.group == widget.group) p,
    ];
    if (items.isEmpty) {
      return PageFrame(
        child: EmptyHint(widget.me.isStaff ? '페이지 편집에서 추가' : '준비 중'),
      );
    }
    final page = items.firstWhere(
      (p) => p.id == _selected,
      orElse: () => items.first,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (departmentChips.isNotEmpty) _chipRow(departmentChips),
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
