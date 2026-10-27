import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/layout/app_dialog.dart';
import '../../../core/layout/confirm_dialog.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../data/models/church_features.dart';
import '../../../data/models/department.dart';
import '../../../data/models/member.dart';
import '../../../data/models/page_layout.dart';
import '../../home/view/content_widgets.dart';
import '../view_model/department_manage_view_model.dart';
import 'department_detail_page.dart';
import '../../../core/theme.dart';

/// 부서 관리: 부서 목록(만들기 · 이름 변경)과 부서별 인원 수. 부서를 누르면 그 부서의 인원을 관리한다.
/// [onOpen]이 없으면(앱 운영자 패널) 전체 화면으로 부서 상세를 연다.
class DepartmentManagePage extends StatelessWidget {
  const DepartmentManagePage({super.key, required this.me, this.onOpen});

  final Member me;
  final void Function(Department department)? onOpen;

  void _open(BuildContext context, Department d) {
    final open = onOpen;
    if (open != null) return open(d);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          // 상단 바 없이 뒤로가기 버튼만 내용 위에 둔다.
          body: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    tooltip: '돌아가기',
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                Expanded(
                  child: DepartmentDetailBody(me: me, departmentId: d.id),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<DepartmentManageViewModel>(
      create: (context) {
        final scope = AppScope.read(context);
        return DepartmentManageViewModel(
          scope.departments,
          scope.members,
          me.churchId,
        );
      },
      builder: (context, vm) => SingleChildScrollView(
        child: PageFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageTitle(title: '부서 관리'),
              // 제목 옆이 아니라 다음 줄에 둔다.
              // 부서를 만들고 고치는 것은 앱을 고치는 일이라 교회 관리자만 한다 (교역자는 조회와 인원 배치).
              if (me.isAdmin) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: () => _edit(context, vm),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('부서 만들기'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              StreamBuilder<List<Department>>(
                stream: vm.departments,
                builder: (context, depts) {
                  if (depts.hasError) {
                    return Text('불러오지 못했습니다\n${depts.error}');
                  }
                  final items = depts.data;
                  if (items == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (items.isEmpty) {
                    return const EmptyHint('만들어진 부서가 없어요.');
                  }
                  return StreamBuilder<List<Member>>(
                    stream: vm.members,
                    builder: (context, members) {
                      final all = members.data ?? const <Member>[];
                      // 부서마다 카드 한 장: 격자로 늘어놓는다 (좁은 화면에서도 두 열).
                      return StreamBuilder<ChurchFeatures>(
                        stream: vm.features,
                        builder: (context, feat) {
                          final features =
                              feat.data ?? ChurchFeatures.unconfigured;
                          return ColumnWrap(
                            wide: 2,
                            narrow: 2,
                            children: [
                              for (final d in items)
                                _DepartmentCard(
                                  department: d,
                                  count: vm.inDepartment(all, d.id).length,
                                  features: features,
                                  canEdit: me.isAdmin,
                                  onOpen: () => _open(context, d),
                                  onRename: () =>
                                      _edit(context, vm, department: d),
                                  onFeature: (group, on) async {
                                    final ok = await confirmChange(
                                      context,
                                      title:
                                          '${d.name}의 ${group.label} 서비스를 ${on ? '켤까요' : '끌까요'}?',
                                      body: on
                                          ? '이 부서 교인이 ${group.label} 탭을 쓸 수 있어요.'
                                          : '이 부서 교인은 ${group.label} 탭을 쓸 수 없어요. 다른 부서에서 허용되면 계속 쓸 수 있어요.',
                                    );
                                    if (ok) {
                                      await vm.setFeature(
                                        features,
                                        items,
                                        d,
                                        group,
                                        on,
                                      );
                                    }
                                  },
                                ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
              if (vm.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    vm.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    DepartmentManageViewModel vm, {
    Department? department,
  }) async {
    final name = await showAppDialog<String>(
      context,
      maxWidth: 420,
      child: _DepartmentNameForm(initial: department?.name),
    );
    if (name == null || name.trim().isEmpty) return;
    if (department == null) {
      await vm.create(name);
    } else {
      await vm.rename(department.id, name);
    }
  }
}

/// 부서 카드: 아이콘, 부서 이름, 인원 수. 누르면 그 부서의 인원 관리가 열리고, 연필로 이름을 바꾼다.
class _DepartmentCard extends StatelessWidget {
  const _DepartmentCard({
    required this.department,
    required this.count,
    required this.features,
    required this.canEdit,
    required this.onOpen,
    required this.onRename,
    required this.onFeature,
  });

  final Department department;
  final int count;
  final ChurchFeatures features;

  /// 이름 변경과 기도 · 말씀 켜기/끄기는 교회 관리자만 한다. 교역자는 보기만 한다.
  final bool canEdit;
  final VoidCallback onOpen;
  final VoidCallback onRename;

  /// 이 부서의 기도 · 말씀 탭을 켜거나 끈다.
  final void Function(PageGroup group, bool on) onFeature;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final radius = BorderRadius.circular(AppRadius.card);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: radius,
        border: Border.all(color: palette.border.withValues(alpha: 0.7)),
        boxShadow: AppShadow.soft(context),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onOpen,
          child: SizedBox(
            height: 184,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: AppDepth.brand(context),
                          borderRadius: BorderRadius.circular(
                            AppRadius.control,
                          ),
                        ),
                        child: Icon(
                          Icons.groups_outlined,
                          size: 22,
                          color: palette.onBrand,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        department.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$count명',
                        style: TextStyle(color: palette.muted, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      // 이 부서가 기도 · 말씀 탭을 쓸 수 있는지.
                      Wrap(
                        spacing: 6,
                        children: [
                          for (final g in const [
                            PageGroup.prayer,
                            PageGroup.word,
                          ])
                            FilterChip(
                              visualDensity: VisualDensity.compact,
                              label: Text(g.label),
                              selected: features.allows(g, department.id),
                              onSelected: canEdit
                                  ? (on) => onFeature(g, on)
                                  : null,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (canEdit)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      tooltip: '이름 변경',
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: onRename,
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

/// 부서 이름 입력 대화상자 내용. 저장하면 입력한 이름을 돌려준다.
class _DepartmentNameForm extends StatefulWidget {
  const _DepartmentNameForm({this.initial});

  final String? initial;

  @override
  State<_DepartmentNameForm> createState() => _DepartmentNameFormState();
}

class _DepartmentNameFormState extends State<_DepartmentNameForm> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.initial == null ? '부서 만들기' : '부서 이름 변경',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        AppField.spacer,
        TextField(
          controller: _controller,
          autofocus: true,
          maxLength: 30,
          decoration: const InputDecoration(labelText: '부서 이름'),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => Navigator.pop(context, _controller.text),
              child: const Text('저장'),
            ),
          ],
        ),
      ],
    );
  }
}
