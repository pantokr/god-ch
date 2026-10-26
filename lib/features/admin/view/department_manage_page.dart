import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/layout/app_dialog.dart';
import '../../../core/layout/manage_list_row.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../data/models/department.dart';
import '../../../data/models/member.dart';
import '../../home/view/content_widgets.dart';
import '../view_model/department_manage_view_model.dart';
import 'department_detail_page.dart';

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
              PageTitle(
                title: '부서 관리',
                subtitle: '부서를 만들고, 부서를 눌러 그 부서의 인원을 관리해요.',
                action: FilledButton.icon(
                  onPressed: () => _edit(context, vm),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('부서 만들기'),
                ),
              ),
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
                      return Card(
                        child: Column(
                          children: [
                            for (var i = 0; i < items.length; i++) ...[
                              if (i > 0) const Divider(),
                              ManageListRow(
                                leading: const CircleAvatar(
                                  child: Icon(Icons.groups_outlined),
                                ),
                                title: items[i].name,
                                line1:
                                    '${vm.inDepartment(all, items[i].id).length}명',
                                onTap: () => _open(context, items[i]),
                                trailing: [
                                  IconButton(
                                    tooltip: '이름 변경',
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 20,
                                    ),
                                    onPressed: () => _edit(
                                      context,
                                      vm,
                                      department: items[i],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right),
                                  const SizedBox(width: 8),
                                ],
                              ),
                            ],
                          ],
                        ),
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
        const SizedBox(height: 16),
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
