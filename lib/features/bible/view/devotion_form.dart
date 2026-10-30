import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/format.dart';
import '../../../core/icons.dart';
import '../../../core/layout/app_dialog.dart';
import '../../../data/models/affiliation.dart';
import '../../../data/models/church_content.dart';
import 'bible_picker_dialog.dart';

/// 말씀 추가 · 수정에서 입력한 값.
class DevotionFormResult {
  const DevotionFormResult(
    this.title,
    this.body,
    this.meditation,
    this.date, {
    this.affiliationId,
    this.isPrivate = false,
  });

  final String title;
  final String body;
  final String meditation;
  final DateTime date;

  /// 분류한 소속. null이면 교회 전체.
  final String? affiliationId;

  /// 비공개 (말씀묵상 비공개 조회 권한이 있는 사람만 볼 수 있다).
  final bool isPrivate;
}

/// 말씀 추가 · 수정 창. 취소하면 null.
Future<DevotionFormResult?> showDevotionForm(
  BuildContext context, {
  required String churchId,

  /// 소속 선택에 올릴 수 있는 소속인가 (교회 관리자는 모두, 그 밖에는 자기 소속만).
  required bool Function(Affiliation) visible,
  ChurchContent? initial,
}) => showAppDialog<DevotionFormResult>(
  context,
  maxWidth: 560,
  child: _Form(churchId: churchId, visible: visible, initial: initial),
);

class _Form extends StatefulWidget {
  const _Form({required this.churchId, required this.visible, this.initial});

  final String churchId;
  final bool Function(Affiliation) visible;
  final ChurchContent? initial;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  late final _title = TextEditingController(text: widget.initial?.title);
  late final _body = TextEditingController(text: widget.initial?.body);
  late final _meditation = TextEditingController(
    text: widget.initial?.meditation,
  );
  late DateTime _date = widget.initial?.date ?? DateTime.now();
  late String? _affiliationId = widget.initial?.affiliationId;
  late bool _private = widget.initial?.isPrivate ?? false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _meditation.dispose();
    super.dispose();
  }

  /// 성경 구절을 골라 제목(구절)과 말씀에 넣는다. 말씀에 이미 쓴 글이 있으면 그 앞에 구절을 둔다.
  Future<void> _pickVerse() async {
    final pick = await showAppDialog<BiblePick>(
      context,
      child: const BiblePickerDialog(),
    );
    if (pick == null) return;
    setState(() {
      _title.text = pick.title;
      final written = _body.text.trim();
      _body.text = written.isEmpty ? pick.body : '${pick.body}\n\n$written';
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.initial == null ? '말씀 추가' : '말씀 수정',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _title,
          autofocus: true,
          maxLength: 100,
          decoration: const InputDecoration(labelText: '구절 (예: 시편 23:1-6)'),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _pickVerse,
            icon: const Icon(AppIcons.bookOpen, size: 18),
            label: const Text('성경 구절 불러오기'),
          ),
        ),
        StreamBuilder<List<Affiliation>>(
          stream: AppScope.read(context).affiliations
              .affiliations(widget.churchId),
          builder: (context, snap) {
            final list = [
              for (final a in snap.data ?? const <Affiliation>[])
                if (widget.visible(a)) a,
            ];
            if (list.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DropdownButtonFormField<String?>(
                initialValue: list.any((a) => a.id == _affiliationId)
                    ? _affiliationId
                    : null,
                decoration: const InputDecoration(labelText: '소속'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('교회 전체')),
                  for (final a in list)
                    DropdownMenuItem(value: a.id, child: Text(a.name)),
                ],
                onChanged: (v) => setState(() => _affiliationId = v),
              ),
            );
          },
        ),
        // 비공개: 말씀묵상 비공개 조회 권한이 있는 사람(교역자)만 볼 수 있다.
        CheckboxListTile(
          value: _private,
          dense: true,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          secondary: const Icon(AppIcons.lock, size: 18),
          title: const Text('비공개 (교역자만)'),
          onChanged: (v) => setState(() => _private = v ?? false),
        ),
        OutlinedButton.icon(
          onPressed: _pickDate,
          icon: const Icon(AppIcons.calendarBlank, size: 18),
          label: Text('날짜  ${fmtDate(_date)}'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _body,
          minLines: 3,
          maxLines: 10,
          maxLength: 5000,
          decoration: const InputDecoration(
            labelText: '말씀',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _meditation,
          minLines: 3,
          maxLines: 10,
          maxLength: 5000,
          decoration: const InputDecoration(
            labelText: '묵상',
            alignLabelWithHint: true,
          ),
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
              onPressed: () => Navigator.pop(
                context,
                DevotionFormResult(
                  _title.text,
                  _body.text,
                  _meditation.text,
                  _date,
                  affiliationId: _affiliationId,
                  isPrivate: _private,
                ),
              ),
              child: const Text('저장'),
            ),
          ],
        ),
      ],
    );
  }
}
