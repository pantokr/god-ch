import '../../../core/widgets/toast.dart';
import '../../../core/icons.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/layout/sub_page.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/affiliation.dart';
import '../../../data/models/member.dart';
import '../../../data/models/prayer.dart';
import '../../church/view_model/affiliations_view_model.dart';
import '../view_model/prayer_editor_view_model.dart';

/// 기도제목 작성 / 수정. [prayer]가 있으면 수정 모드.
class PrayerEditorPage extends StatefulWidget {
  const PrayerEditorPage({
    super.key,
    required this.me,
    this.defaultAffiliationId,
    this.prayer,
  });

  final Member me;

  /// 새 글의 기본 게시 범위. null이면 교회 전체.
  final String? defaultAffiliationId;
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

  /// 작성·수정이 끝나거나 취소하면 이전 화면으로 돌아간다 (주소로 바로 열었다면 기도제목 목록으로).
  void _leave(GoRouter router) {
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(Routes.section(widget.me.churchId, ChurchSection.prayer));
    }
  }

  Future<void> _save(PrayerEditorViewModel vm) async {
    if (!_form.currentState!.validate()) return;
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await vm.save(
      title: _title.text.trim(),
      content: _content.text.trim(),
    );
    if (ok) {
      _leave(router);
      // 새로 쓴 글만 "추가되었습니다" (고친 글은 알리지 않는다).
      if (!vm.isEditing) showToastOn(messenger, '추가되었습니다');
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
        defaultAffiliationId: widget.defaultAffiliationId,
      ),
      builder: (context, vm) => SubPage(
        title: vm.isEditing ? '기도제목 수정' : '기도제목 쓰기',
        fallbackLocation: Routes.section(
          widget.me.churchId,
          ChurchSection.prayer,
        ),
        child: !vm.canWrite
            ? const Card(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: Text('교역자만 쓸 수 있습니다')),
                ),
              )
            : Card(
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
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? '제목을 입력해 주세요'
                              : null,
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
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? '내용을 입력해 주세요'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        // 게시 범위는 새 글을 쓸 때만 고를 수 있다.
                        if (!vm.isEditing) _ScopePicker(vm: vm),
                        // 교회가 비공개를 허용하지 않으면 공개 범위를 고를 수 없다.
                        if (vm.settings.allowPrivate) _VisibilityPicker(vm: vm),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: vm.busy
                                  ? null
                                  : () => _leave(GoRouter.of(context)),
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

/// 게시 범위: 교회 전체 또는 내가 속한 소속(교역자는 모든 소속).
class _ScopePicker extends StatelessWidget {
  const _ScopePicker({required this.vm});

  final PrayerEditorViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<AffiliationsViewModel>(
      create: (context) => AffiliationsViewModel(
        AppScope.read(context).affiliations,
        vm.me.churchId,
      ),
      builder: (context, affs) => StreamBuilder<List<Affiliation>>(
        stream: affs.affiliations,
        builder: (context, snap) {
          final mine = (snap.data ?? const <Affiliation>[])
              .where(
                (a) => vm.me.isStaff || vm.me.affiliationIds.contains(a.id),
              )
              .toList();
          // 고를 소속이 없으면 항상 교회 전체이므로 입력란을 보여주지 않는다.
          if (mine.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: DropdownButtonFormField<String?>(
              initialValue: mine.any((a) => a.id == vm.affiliationId)
                  ? vm.affiliationId
                  : null,
              decoration: const InputDecoration(labelText: '게시 범위'),
              items: [
                const DropdownMenuItem(value: null, child: Text('교회 전체')),
                for (final a in mine)
                  DropdownMenuItem(value: a.id, child: Text('${a.name} 전용')),
              ],
              onChanged: vm.setAffiliation,
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
              icon: Icon(AppIcons.globe, size: 18),
              label: Text('공개'),
            ),
            ButtonSegment(
              value: PrayerVisibility.private,
              icon: Icon(AppIcons.lock, size: 18),
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
          style: TextStyle(color: context.palette.muted, fontSize: 13),
        ),
      ],
    );
  }
}
