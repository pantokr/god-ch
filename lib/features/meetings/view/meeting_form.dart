import 'package:flutter/material.dart';

import '../../../core/widgets/labeled_field.dart';

import 'package:flutter/services.dart';

import '../../../app/app_scope.dart';
import '../../../core/icons.dart';
import '../../../core/layout/sub_page.dart';
import '../../../core/widgets/choice_row.dart';
import '../../../core/widgets/app_date_picker.dart';
import '../../../core/widgets/thumbnail_field.dart';
import '../../../data/models/affiliation.dart';
import '../../../data/models/meeting.dart';
import '../../../data/models/member.dart';
import 'meeting_format.dart';

/// 모임 만들기 · 수정에서 입력한 값.
class MeetingFormResult {
  const MeetingFormResult({
    required this.title,
    required this.description,
    required this.place,
    required this.date,
    required this.capacity,
    this.fee = 0,
    this.needsApproval = false,
    this.imageUrl = '',
    this.affiliationId,
  });

  /// 공개 범위(소속). null이면 교회 전체.
  final String? affiliationId;
  final String imageUrl;
  final String title;
  final String description;
  final String place;
  final DateTime date;
  final int capacity;

  /// 회비 (원). 0이면 무료.
  final int fee;

  /// 입장 조건: 참여 신청을 모임장이 승인해야 하는가.
  final bool needsApproval;
}

/// 모임 만들기 · 수정 화면. 중보기도 요청 · 말씀묵상 작성과 같은 모양의 페이지(상단 탭 + 카드 두 장)다. 취소하면 null.
Future<MeetingFormResult?> showMeetingForm(
  BuildContext context, {
  Meeting? initial,
  required Member me,
  required Future<String?> Function(String fileName, Uint8List bytes) upload,
}) => Navigator.of(context, rootNavigator: true).push<MeetingFormResult>(
  MaterialPageRoute(
    builder: (_) => Builder(
      builder: (context) => SubPage(
        title: '',
        barTitle: initial == null ? '모임 만들기' : '모임 수정',
        fallbackLocation: '',
        onBack: () => Navigator.of(context).maybePop(),
        child: _Form(initial: initial, me: me, upload: upload),
      ),
    ),
  ),
);

class _Form extends StatefulWidget {
  const _Form({this.initial, required this.me, required this.upload});

  final Meeting? initial;
  final Member me;
  final Future<String?> Function(String fileName, Uint8List bytes) upload;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  late final _title = TextEditingController(text: widget.initial?.title);
  late final _image = TextEditingController(text: widget.initial?.imageUrl);
  late final _place = TextEditingController(text: widget.initial?.place);
  late final _description = TextEditingController(
    text: widget.initial?.description,
  );
  late final _capacity = TextEditingController(
    text: '${widget.initial?.capacity ?? 8}',
  );
  late final _fee = TextEditingController(
    text: (widget.initial?.fee ?? 0) > 0 ? '${widget.initial!.fee}' : '',
  );
  // 회비 유무를 먼저 고르고, 있으면 금액을 입력한다.
  late bool _hasFee = (widget.initial?.fee ?? 0) > 0;
  late bool _needsApproval = widget.initial?.needsApproval ?? false;
  late String? _affiliationId = widget.initial?.affiliationId;
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
    _image.dispose();
    _title.dispose();
    _place.dispose();
    _description.dispose();
    _capacity.dispose();
    _fee.dispose();
    super.dispose();
  }

  /// 날짜만 고른다 (시각은 그대로).
  Future<void> _pickDate() async {
    final day = await showAppDatePicker(
      context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      title: '모임 날짜',
    );
    if (day == null || !mounted) return;
    setState(() {
      _date = DateTime(day.year, day.month, day.day, _date.hour, _date.minute);
    });
  }

  /// 시각만 고른다 (날짜는 그대로).
  Future<void> _pickTime() async {
    final time = await showAppTimePicker(
      context,
      initialTime: TimeOfDay.fromDateTime(_date),
      title: '모임 시각',
    );
    if (time == null || !mounted) return;
    setState(() {
      _date = DateTime(
        _date.year,
        _date.month,
        _date.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const cardPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 24);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 본문 카드: 썸네일 · 일정 · 제목 · 소개.
        Card(
          child: Padding(
            padding: cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ThumbnailField(
                  controller: _image,
                  name: _title.text,
                  upload: widget.upload,
                  label: '썸네일',
                  aspectRatio: meetingThumbRatio,
                ),
                const SizedBox(height: 20),
                LabeledField(
                  label: '제목',
                  child: TextField(
                    controller: _title,
                    maxLength: Meeting.maxTitle,
                    decoration: const InputDecoration(counterText: ''),
                  ),
                ),
                const SizedBox(height: 8),
                // 이름표 없이 입력칸 안의 힌트로 안내한다.
                TextField(
                  controller: _description,
                  minLines: 6,
                  maxLines: 16,
                  maxLength: Meeting.maxDescription,
                  decoration: const InputDecoration(
                    hintText: '소개를 적어주세요',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // 설정 카드: 일정 · 장소 · 정원 · 회비 · 입장 조건과 저장.
        Card(
          child: Padding(
            padding: cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 일시: 달력 버튼과 시계 버튼이 따로 있다.
                LabeledField(
                  label: '일시',
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(AppIcons.calendarBlank, size: 18),
                          label: Text(
                            '${_date.month}월 ${_date.day}일 ${'월화수목금토일'[_date.weekday - 1]}요일',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(AppIcons.clock, size: 18),
                        label: Text(
                          '${_date.hour.toString().padLeft(2, '0')}:${_date.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                LabeledField(
                  label: '장소',
                  child: TextField(
                    controller: _place,
                    maxLength: Meeting.maxPlace,
                    decoration: const InputDecoration(counterText: ''),
                  ),
                ),
                const SizedBox(height: 8),
                LabeledField(
                  label: '정원',
                  child: TextField(
                    controller: _capacity,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(hintText: '모임장 포함'),
                  ),
                ),
                const SizedBox(height: 16),
                ChoiceRow<bool>(
                  label: '회비',
                  options: const [
                    ChoiceOption(false, '없음'),
                    ChoiceOption(true, '있음'),
                  ],
                  value: _hasFee,
                  onChanged: (v) => setState(() => _hasFee = v),
                ),
                const SizedBox(height: 8),
                // 회비 금액 칸은 늘 보이고, 회비가 "있음"일 때만 입력할 수 있다 (아니면 흐리게 막힌다).
                Opacity(
                  opacity: _hasFee ? 1 : 0.45,
                  child: LabeledField(
                    label: '회비 금액',
                    child: TextField(
                      controller: _fee,
                      enabled: _hasFee,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(suffixText: '원'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 입장 조건: 모임장이 참여 신청을 승인해야 하는가.
                ChoiceRow<bool>(
                  label: '입장 조건',
                  options: const [
                    ChoiceOption(false, '자유 참여'),
                    ChoiceOption(true, '모임장 승인'),
                  ],
                  value: _needsApproval,
                  onChanged: (v) => setState(() => _needsApproval = v),
                ),
                const SizedBox(height: 16),
                // 공개 범위: 참여할 수 있는 소속. 교역자 이상은 교회 전체도 고를 수 있다.
                StreamBuilder<List<Affiliation>>(
                  stream: AppScope.read(context).affiliations
                      .affiliations(widget.me.churchId),
                  builder: (context, snap) {
                    final staff = widget.me.isStaff;
                    final list = [
                      for (final a in snap.data ?? const <Affiliation>[])
                        if (staff || widget.me.affiliationIds.contains(a.id)) a,
                    ];
                    // 고를 수 있는 소속이 없고 교역자도 아니면 늘 교회 전체다.
                    if (list.isEmpty && !staff) return const SizedBox.shrink();
                    // 교역자가 아니면 교회 전체는 고를 수 없다: 고른 소속이 없으면 첫 소속이 골라진다.
                    final chosen = list.any((a) => a.id == _affiliationId);
                    final value = chosen
                        ? _affiliationId
                        : (staff ? null : list.first.id);
                    if (!staff && !chosen) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() => _affiliationId = list.first.id);
                        }
                      });
                    }
                    return LabeledField(
                      label: '공개 범위',
                      child: DropdownButtonFormField<String?>(
                        initialValue: value,
                        decoration: const InputDecoration(),
                        items: [
                          if (staff)
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('전체'),
                            ),
                          for (final a in list)
                            DropdownMenuItem<String?>(
                              value: a.id,
                              child: Text(a.name),
                            ),
                        ],
                        onChanged: (v) => setState(() => _affiliationId = v),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
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
                          fee: _hasFee ? (int.tryParse(_fee.text) ?? 0) : 0,
                          needsApproval: _needsApproval,
                          imageUrl: _image.text,
                          affiliationId: _affiliationId,
                        ),
                      ),
                      child: const Text('저장'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
