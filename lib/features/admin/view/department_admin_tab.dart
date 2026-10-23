import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/layout/app_dialog.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/department.dart';
import '../../../data/models/member.dart';
import '../../church/view_model/departments_view_model.dart';

/// 부서 만들기·이름 변경. 소속은 교인이 직접 선택한다.
class DepartmentAdminTab extends StatelessWidget {
  const DepartmentAdminTab({super.key, required this.me});

  final Member me;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<DepartmentsViewModel>(
      create: (context) =>
          DepartmentsViewModel(AppScope.read(context).departments, me.churchId),
      builder: (context, vm) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FilledButton.icon(
              onPressed: () => _edit(context, vm),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('부서 만들기'),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<Department>>(
              stream: vm.departments,
              builder: (context, snap) {
                if (snap.hasError) return Text('불러오지 못했습니다\n${snap.error}');
                final items = snap.data;
                if (items == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (items.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      '만들어진 부서가 없어요.',
                      style: TextStyle(color: context.palette.muted),
                    ),
                  );
                }
                return Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        if (i > 0) const Divider(),
                        ListTile(
                          leading: const Icon(Icons.groups_outlined),
                          title: Text(items[i].name),
                          trailing: TextButton.icon(
                            onPressed: () =>
                                _edit(context, vm, department: items[i]),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('이름 변경'),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    DepartmentsViewModel vm, {
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
