import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/icons.dart';
import '../../../core/layout/app_dialog.dart';
import '../../../data/models/meeting.dart';
import 'meeting_format.dart';

/// 모임 만들기 · 수정에서 입력한 값.
class MeetingFormResult {
  const MeetingFormResult({
    required this.title,
    required this.description,
    required this.place,
    required this.date,
    required this.capacity,
  });

  final String title;
  final String description;
  final String place;
  final DateTime date;
  final int capacity;
}

/// 모임 만들기 · 수정 창. 취소하면 null.
Future<MeetingFormResult?> showMeetingForm(
  BuildContext context, {
  Meeting? initial,
}) => showAppDialog<MeetingFormResult>(
  context,
  maxWidth: 520,
  child: _Form(initial: initial),
);

class _Form extends StatefulWidget {
  const _Form({this.initial});

  final Meeting? initial;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  late final _title = TextEditingController(text: widget.initial?.title);
  late final _place = TextEditingController(text: widget.initial?.place);
  late final _description = TextEditingController(
    text: widget.initial?.description,
  );
  late final _capacity = TextEditingController(
    text: '${widget.initial?.capacity ?? 8}',
  );
  late DateTime _date =
      widget.initial?.date ??
      DateTime.now()
          .add(const Duration(days: 7))
          .copyWith(
            hour: 19,
            minute: 30,
            second: 0,
            millisecond: 0,
            microsecond: 0,
          );

  @override
  void dispose() {
    _title.dispose();
    _place.dispose();
    _description.dispose();
    _capacity.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final day = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (!mounted) return;
    setState(() {
      _date = DateTime(
        day.year,
        day.month,
        day.day,
        time?.hour ?? _date.hour,
        time?.minute ?? _date.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.initial == null ? '모임 만들기' : '모임 수정',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _title,
          autofocus: true,
          maxLength: Meeting.maxTitle,
          decoration: const InputDecoration(labelText: '제목'),
        ),
        OutlinedButton.icon(
          onPressed: _pickDate,
          icon: const Icon(AppIcons.calendarBlank, size: 18),
          label: Text(meetingWhen(_date)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _place,
          maxLength: Meeting.maxPlace,
          decoration: const InputDecoration(labelText: '장소'),
        ),
        TextField(
          controller: _capacity,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: '정원 (모임장 포함)'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _description,
          minLines: 3,
          maxLines: 8,
          maxLength: Meeting.maxDescription,
          decoration: const InputDecoration(
            labelText: '소개',
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
                MeetingFormResult(
                  title: _title.text,
                  description: _description.text,
                  place: _place.text,
                  date: _date,
                  capacity: int.tryParse(_capacity.text) ?? 0,
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
