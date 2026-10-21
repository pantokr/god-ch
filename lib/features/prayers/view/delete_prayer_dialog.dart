import 'package:flutter/material.dart';

import '../../../core/layout/app_dialog.dart';

/// 삭제 확인 대화상자. 삭제하면 사유(본인 글이면 빈 문자열)를, 취소하면 null을 돌려준다.
/// [needsReason]이 true면 사유를 입력해야 삭제할 수 있다.
Future<String?> showDeletePrayerDialog(
  BuildContext context, {
  required bool needsReason,
}) => showAppDialog<String>(
  context,
  child: _DeletePrayerForm(needsReason: needsReason),
);

class _DeletePrayerForm extends StatefulWidget {
  const _DeletePrayerForm({required this.needsReason});

  final bool needsReason;

  @override
  State<_DeletePrayerForm> createState() => _DeletePrayerFormState();
}

class _DeletePrayerFormState extends State<_DeletePrayerForm> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  bool get _canSubmit => !widget.needsReason || _reason.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('기도제목을 삭제할까요?', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        if (widget.needsReason)
          TextField(
            controller: _reason,
            autofocus: true,
            maxLines: 2,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: '삭제 사유 (필수)'),
          )
        else
          const Text('삭제한 기도제목은 목록에서 사라집니다.'),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _canSubmit
                  ? () => Navigator.pop(context, _reason.text.trim())
                  : null,
              child: const Text('삭제'),
            ),
          ],
        ),
      ],
    );
  }
}
