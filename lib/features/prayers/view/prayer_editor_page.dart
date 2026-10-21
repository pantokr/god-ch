import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/layout/sub_page.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/department.dart';
import '../../../data/models/member.dart';
import '../../../data/models/prayer.dart';
import '../../church/view_model/departments_view_model.dart';
import '../view_model/prayer_editor_view_model.dart';

/// 기도제목 작성 / 수정. [prayer]가 있으면 수정 모드.
class PrayerEditorPage extends StatefulWidget {
  const PrayerEditorPage({
    super.key,
    required this.me,
    this.defaultDepartmentId,
    this.prayer,
  });

  final Member me;

  /// 새 글의 기본 게시 범위. null이면 교회 전체.
  final String? defaultDepartmentId;
  final Prayer? prayer;

  @override
  State<PrayerEditorPage> createState() => _PrayerEditorPageState();
}

class _PrayerEditorPageState extends State<PrayerEditorPage> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.prayer?.title);
  late final _content = TextEditingController(text: widget.prayer?.content);

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _save(PrayerEditorViewModel vm) async {
    if (!_form.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await vm.save(
      title: _title.text.trim(),
      content: _content.text.trim(),
    );
    if (ok) {
      navigator.pop();
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text('저장하지 못했습니다: ${vm.error}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<PrayerEditorViewModel>(
      create: (context) => PrayerEditorViewModel(
        AppScope.read(context).prayers,
        widget.me,
        existing: widget.prayer,
        defaultDepartmentId: widget.defaultDepartmentId,
      ),
      builder: (context, vm) => SubPage(
        title: vm.isEditing ? '기도제목 수정' : '기도제목 쓰기',
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _title,
                    maxLength: 100,
                    decoration: const InputDecoration(labelText: '제목'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? '제목을 입력해 주세요' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _content,
                    maxLength: 3000,
                    minLines: 8,
                    maxLines: 16,
                    decoration: const InputDecoration(
                      labelText: '기도제목',
                      alignLabelWithHint: true,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? '내용을 입력해 주세요' : null,
                  ),
                  const SizedBox(height: 16),
                  // 게시 범위는 새 글을 쓸 때만 고를 수 있다.
                  if (!vm.isEditing) _ScopePicker(vm: vm),
                  _VisibilityPicker(vm: vm),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: vm.busy
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('취소'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: vm.busy ? null : () => _save(vm),
                        child: const Text('저장'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 게시 범위: 교회 전체 또는 내가 소속된 부서(교역자는 모든 부서).
class _ScopePicker extends StatelessWidget {
  const _ScopePicker({required this.vm});

  final PrayerEditorViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<DepartmentsViewModel>(
      create: (context) => DepartmentsViewModel(
        AppScope.read(context).departments,
        vm.me.churchId,
      ),
      builder: (context, departments) => StreamBuilder<List<Department>>(
        stream: departments.departments,
        builder: (context, snap) {
          final mine = (snap.data ?? const <Department>[])
              .where((d) => vm.me.isStaff || vm.me.departmentIds.contains(d.id))
              .toList();
          // 선택할 부서가 없으면 항상 교회 전체이므로 입력란을 보여주지 않는다.
          if (mine.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: DropdownButtonFormField<String?>(
              initialValue: mine.any((d) => d.id == vm.departmentId)
                  ? vm.departmentId
                  : null,
              decoration: const InputDecoration(labelText: '게시 범위'),
              items: [
                const DropdownMenuItem(value: null, child: Text('교회 전체')),
                for (final d in mine)
                  DropdownMenuItem(value: d.id, child: Text('${d.name} 전용')),
              ],
              onChanged: vm.setDepartment,
            ),
          );
        },
      ),
    );
  }
}

class _VisibilityPicker extends StatelessWidget {
  const _VisibilityPicker({required this.vm});

  final PrayerEditorViewModel vm;

  @override
  Widget build(BuildContext context) {
    final isPublic = vm.visibility == PrayerVisibility.public;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('공개 범위', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<PrayerVisibility>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: PrayerVisibility.public,
              icon: Icon(Icons.public, size: 18),
              label: Text('공개'),
            ),
            ButtonSegment(
              value: PrayerVisibility.private,
              icon: Icon(Icons.lock_outline, size: 18),
              label: Text('교역자 전용'),
            ),
          ],
          selected: {vm.visibility},
          onSelectionChanged: (s) => vm.setVisibility(s.first),
        ),
        const SizedBox(height: 8),
        Text(
          isPublic
              ? '승인된 교인에게 공개되며 이모티콘으로 응원받을 수 있어요. 작성자 이름은 표시되지 않습니다.'
              : '다른 교인에게는 보이지 않고, 교역자만 읽고 답변할 수 있어요.',
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
      ],
    );
  }
}
