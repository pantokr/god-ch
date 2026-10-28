import '../../../core/icons.dart';

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
import '../../prayers/view/prayer_write_fab.dart';

/// 하단 가운데 "홈"과 양옆 버튼(왼쪽 · 오른쪽)의 화면.
/// - 홈: 홈 자리의 페이지들을 위에서 아래로 이어 붙인다 (순서는 페이지 편집에서 정한다).
/// - 왼쪽 · 오른쪽: 그 자리에 놓인 페이지 하나를 화면 전체로 보여준다.
///
/// 기도 요청 · 말씀 묵상 페이지는 어느 자리에 있든 교역자가 부서별로 켜고 끈다 ([ChurchFeatures]).
/// - 소속 부서가 모두 꺼져 있으면 서비스가 허용되지 않았다는 안내만 보인다.
/// - 소속 부서 중 쓸 수 있는 부서가 여럿이면 위쪽 탭(서랍 버튼 줄) 오른쪽에서 부서를 고른다 ([DepartmentSelect]).
class GroupHubPage extends StatelessWidget {
  const GroupHubPage({
    super.key,
    required this.group,
    required this.pages,
    required this.me,
    required this.choice,
    this.department,
    this.page,
  });

  final PageGroup group;

  /// 보여줄 페이지를 직접 정한다 (좌측 탭의 페이지). 없으면 [group] 자리의 페이지.
  final PageConfig? page;

  /// 교회의 모든 페이지. 이 중 [group]에 속한 것만 보인다.
  final List<PageConfig> pages;
  final Member me;

  /// 지금 고른 부서 (위쪽 탭의 부서 선택과 함께 쓴다).
  final DepartmentChoice choice;
  final Department? department;

  @override
  Widget build(BuildContext context) {
    if (group == PageGroup.home) return _home(department);
    final page = this.page ?? slotPage(pages, group);
    if (page == null) {
      return PageFrame(child: EmptyHint(me.isStaff ? '페이지 편집에서 추가' : '준비 중'));
    }
    final feature = PageFeature.of(page.template?.type);
    if (feature == null) return _slot(context, page, department);
    // 앱 개발자는 교회를 고칠 수 있어도 기도제목 내용은 볼 수 없다.
    if (me.isOperatorView && feature == PageFeature.prayer) {
      return const _OperatorNotice();
    }
    return ViewModelBuilder<GroupAccessViewModel>(
      key: ValueKey('access/${me.churchId}'),
      create: (context) =>
          GroupAccessViewModel(AppScope.read(context).departments, me.churchId),
      builder: (context, vm) => StreamBuilder<List<Department>>(
        stream: vm.departments,
        builder: (context, depts) => StreamBuilder<ChurchFeatures>(
          stream: vm.features,
          builder: (context, feat) {
            if (!depts.hasData || !feat.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final access = feat.data!.accessFor(feature, me, depts.data!);
            if (access.blocked) return _NotAllowed(feature: feature);
            // 부서는 위쪽 탭(서랍 버튼 줄) 오른쪽에서 고르고, 소속 부서가 없으면 교회 전체다.
            return ListenableBuilder(
              listenable: choice,
              builder: (context, _) => _slot(
                context,
                page,
                chosenDepartment(access, choice) ?? department,
              ),
            );
          },
        ),
      ),
    );
  }

  /// 홈은 탭으로 나누지 않고 페이지들을 한 화면에 위에서 아래로 이어 붙인다.
  Widget _home(Department? department) {
    final items = [
      for (final p in pages)
        if (p.group == PageGroup.home) p,
    ];
    if (items.isEmpty) {
      return PageFrame(child: EmptyHint(me.isStaff ? '페이지 편집에서 추가' : '준비 중'));
    }
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
                me: me,
                department: department,
              ),
          ],
        ),
      ),
    );
  }

  /// 왼쪽 · 오른쪽 버튼, 좌측 탭의 페이지 하나를 보여준다.
  /// 기도 요청 페이지는 기도 요청 버튼이 오른쪽 아래에 떠 있다 (배경은 바깥 틀이 깐다).
  Widget _slot(BuildContext context, PageConfig page, Department? department) {
    final view = ChurchPageView(
      key: ValueKey('hub/${page.id}/${department?.id}'),
      page: page,
      me: me,
      department: department,
      // 템플릿(기도 요청 · 말씀 묵상)은 페이지 제목도 카드도 없이 화면 전체를 쓴다.
      fullScreen: page.hasTemplate,
    );
    if (page.template?.type != BlockType.prayer) return view;
    return Stack(
      fit: StackFit.expand,
      children: [
        view,
        Positioned(
          right: 16,
          bottom: 16,
          child: PrayerWriteFab(me: me, department: department),
        ),
      ],
    );
  }
}

/// [group](왼쪽 · 오른쪽) 자리에 놓인 페이지. 비어 있으면 null.
PageConfig? slotPage(List<PageConfig> pages, PageGroup group) =>
    pages.where((p) => p.group == group).firstOrNull;

/// 소속 부서에서 이 기능이 꺼져 있을 때의 안내.
class _NotAllowed extends StatelessWidget {
  const _NotAllowed({required this.feature});

  final PageFeature feature;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.lock, size: 40, color: palette.muted),
            const SizedBox(height: 16),
            Text(
              '본 서비스가 허용되지 않았습니다',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '소속 부서에서 ${feature.label} 서비스를 사용할 수 없습니다.\n담당 교역자에게 문의해 주세요.',
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
