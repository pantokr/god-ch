import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/layout/app_dialog.dart';
import '../../../core/layout/manage_list_row.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/department.dart';
import '../../../data/models/member.dart';
import '../../home/view/content_widgets.dart';
import '../view_model/department_manage_view_model.dart';
import '../../../core/widgets/app_inputs.dart';

/// 한 부서의 인원 관리 (주소 `/churches/{교회}/departments/{부서}`). 목록으로 돌아가는 버튼이 있다.
class DepartmentDetailPage extends StatelessWidget {
  const DepartmentDetailPage({
    super.key,
    required this.me,
    required this.departmentId,
  });

  final Member me;
  final String departmentId;

  @override
  Widget build(BuildContext context) => DepartmentDetailBody(
    me: me,
    departmentId: departmentId,
    onBack: () => context.canPop()
        ? context.pop()
        : context.go(Routes.section(me.churchId, ChurchSection.departments)),
  );
}

/// 부서 상세의 본문. 앱 운영자 패널에서는 [onBack] 없이 쓴다(앱 바의 뒤로가기를 쓴다).
class DepartmentDetailBody extends StatelessWidget {
  const DepartmentDetailBody({
    super.key,
    required this.me,
    required this.departmentId,
    this.onBack,
  });

  final Member me;
  final String departmentId;
  final VoidCallback? onBack;

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
      builder: (context, vm) => StreamBuilder<List<Department>>(
        stream: vm.departments,
        builder: (context, depts) {
          if (!depts.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final department = depts.data!
              .where((d) => d.id == departmentId)
              .firstOrNull;
          if (department == null) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: EmptyHint('없는 부서예요.'),
            );
          }
          return StreamBuilder<List<Member>>(
            stream: vm.members,
            builder: (context, members) {
              final all = members.data ?? const <Member>[];
              final people = vm.inDepartment(all, departmentId);
              return SingleChildScrollView(
                child: PageFrame(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (onBack != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: onBack,
                            icon: const Icon(Icons.arrow_back, size: 18),
                            label: const Text('부서 목록'),
                          ),
                        ),
                      PageTitle(
                        title: department.name,
                        action: FilledButton.icon(
                          onPressed: vm.busy
                              ? null
                              : () => _add(context, vm, all),
                          icon: const Icon(Icons.person_add_alt, size: 18),
                          label: const Text('인원 추가'),
                        ),
                      ),
                      if (vm.error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            vm.error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      if (people.isEmpty)
                        const EmptyHint('이 부서에 속한 인원이 없어요.')
                      else
                        Card(
                          child: Column(
                            children: [
                              for (var i = 0; i < people.length; i++) ...[
                                if (i > 0) const Divider(),
                                _PersonRow(
                                  member: people[i],
                                  busy: vm.busy,
                                  onRemove: () =>
                                      vm.remove(departmentId, people[i]),
                                ),
                              ],
                            ],
                          ),
                        ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _add(
    BuildContext context,
    DepartmentManageViewModel vm,
    List<Member> all,
  ) async {
    final picked = await showAppDialog<List<Member>>(
      context,
      maxWidth: 480,
      child: _AddPeopleForm(candidates: vm.candidates(all, departmentId)),
    );
    if (picked == null || picked.isEmpty) return;
    await vm.add(departmentId, picked);
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.member,
    required this.busy,
    required this.onRemove,
  });

  final Member member;
  final bool busy;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    // 다른 관리 목록과 같은 줄 모양: 이름 · 소속 교회 · 소속 부서(이 부서) · [빼기].
    return ManageListRow(
      leading: ManageListRow.avatar(context, member.name),
      title: member.loginId.isEmpty
          ? member.name
          : '${member.name}  (${member.loginId})',
      line1: member.churchName,
      line2: member.phone,
      trailing: [
        TextButton(onPressed: busy ? null : onRemove, child: const Text('빼기')),
      ],
    );
  }
}

/// 부서에 넣을 인원을 고르는 대화상자. 이름·전화번호로 찾고 여러 명을 한꺼번에 고른다.
class _AddPeopleForm extends StatefulWidget {
  const _AddPeopleForm({required this.candidates});

  final List<Member> candidates;

  @override
  State<_AddPeopleForm> createState() => _AddPeopleFormState();
}

class _AddPeopleFormState extends State<_AddPeopleForm> {
  String _query = '';
  final _picked = <String>{};

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final shown = widget.candidates
        .where(
          (m) =>
              q.isEmpty ||
              m.name.toLowerCase().contains(q) ||
              m.phone.replaceAll('-', '').contains(q.replaceAll('-', '')),
        )
        .toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('인원 추가', style: Theme.of(context).textTheme.titleLarge),
        AppField.spacer,
        AppSearchField(
          autofocus: true,
          hint: '이름이나 전화번호로 찾기',
          onChanged: (v) => setState(() => _query = v.trim()),
        ),
        const SizedBox(height: 8),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              widget.candidates.isEmpty ? '추가할 수 있는 인원이 없어요.' : '찾는 인원이 없어요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.palette.muted),
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final m in shown)
                  CheckboxListTile(
                    dense: true,
                    value: _picked.contains(m.id),
                    onChanged: (on) => setState(
                      () =>
                          on == true ? _picked.add(m.id) : _picked.remove(m.id),
                    ),
                    title: Text(m.name),
                    subtitle: m.phone.isEmpty ? null : Text(m.phone),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _picked.isEmpty
                  ? null
                  : () => Navigator.pop(context, [
                      for (final m in widget.candidates)
                        if (_picked.contains(m.id)) m,
                    ]),
              child: Text(_picked.isEmpty ? '추가' : '${_picked.length}명 추가'),
            ),
          ],
        ),
      ],
    );
  }
}
