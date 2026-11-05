import 'package:flutter/material.dart';

import '../icons.dart';
import '../theme.dart';

const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

/// 앱 전용 달력. 모든 글자가 한글이다. 날짜를 고르면 [DateTime](시각 없음)을 돌려주고, 닫으면 null이다.
/// - 맨 위에 고른 날짜를 크게 보여준다 ("26년 11월 6일 금요일").
/// - 달 이름을 누르면 해와 달을 바로 고르는 화면으로 바뀐다.
/// - 고른 날은 입력칸과 같은 모서리(세 곳은 둥글고 왼쪽 아래만 각진)의 강조색 칸, 오늘은 같은 모양의 테두리다.
Future<DateTime?> showAppDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String title = '날짜 선택',
}) => showDialog<DateTime>(
  context: context,
  builder: (_) => Dialog(
    insetPadding: const EdgeInsets.all(16),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: _DatePickerBody(
        initial: DateUtils.dateOnly(initialDate),
        first: DateUtils.dateOnly(firstDate),
        last: DateUtils.dateOnly(lastDate),
        title: title,
      ),
    ),
  ),
);

class _DatePickerBody extends StatefulWidget {
  const _DatePickerBody({
    required this.initial,
    required this.first,
    required this.last,
    required this.title,
  });

  final DateTime initial;
  final DateTime first;
  final DateTime last;
  final String title;

  @override
  State<_DatePickerBody> createState() => _DatePickerBodyState();
}

class _DatePickerBodyState extends State<_DatePickerBody> {
  late DateTime _selected = _clamp(widget.initial);

  /// 지금 보고 있는 달의 1일.
  late DateTime _month = DateTime(_selected.year, _selected.month);

  /// true이면 해 · 달 고르기 화면이다.
  bool _pickingMonth = false;

  /// 달 고르기 화면에서 보고 있는 해.
  late int _year = _selected.year;

  DateTime _clamp(DateTime d) => d.isBefore(widget.first)
      ? widget.first
      : (d.isAfter(widget.last) ? widget.last : d);

  bool _enabled(DateTime d) =>
      !d.isBefore(widget.first) && !d.isAfter(widget.last);

  bool _monthEnabled(int year, int month) =>
      !DateTime(year, month + 1, 0).isBefore(widget.first) &&
      !DateTime(year, month).isAfter(widget.last);

  void _moveMonth(int delta) {
    final next = DateTime(_month.year, _month.month + delta);
    if (!_monthEnabled(next.year, next.month)) return;
    setState(() => _month = next);
  }

  String _headline(DateTime d) =>
      '${d.year % 100}년 ${d.month}월 ${d.day}일 ${_weekdays[d.weekday - 1]}요일';

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            style: TextStyle(
              color: palette.muted,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _headline(_selected),
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: palette.border),
          const SizedBox(height: 10),
          _pickingMonth ? _monthPicker(context) : _dayGrid(context),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: _enabled(DateUtils.dateOnly(DateTime.now()))
                    ? () => setState(() {
                        final today = DateUtils.dateOnly(DateTime.now());
                        _selected = today;
                        _month = DateTime(today.year, today.month);
                        _pickingMonth = false;
                      })
                    : null,
                child: const Text('오늘'),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              const SizedBox(width: 4),
              FilledButton(
                onPressed: () => Navigator.pop(context, _selected),
                child: const Text('확인'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 위쪽 줄: ‹ 26년 11월 ›. 가운데를 누르면 해 · 달 고르기로 바뀐다.
  Widget _header(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: [
        IconButton(
          tooltip: '이전 달',
          visualDensity: VisualDensity.compact,
          onPressed:
              _monthEnabled(
                DateTime(_month.year, _month.month - 1).year,
                DateTime(_month.year, _month.month - 1).month,
              )
              ? () => _moveMonth(-1)
              : null,
          icon: const Icon(AppIcons.caretLeft, size: 18),
        ),
        Expanded(
          child: InkWell(
            borderRadius: AppField.radius,
            onTap: () => setState(() {
              _pickingMonth = true;
              _year = _month.year;
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_month.year % 100}년 ${_month.month}월',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(AppIcons.caretDown, size: 14, color: palette.muted),
                ],
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: '다음 달',
          visualDensity: VisualDensity.compact,
          onPressed:
              _monthEnabled(
                DateTime(_month.year, _month.month + 1).year,
                DateTime(_month.year, _month.month + 1).month,
              )
              ? () => _moveMonth(1)
              : null,
          icon: const Icon(AppIcons.caretRight, size: 18),
        ),
      ],
    );
  }

  Widget _dayGrid(BuildContext context) {
    final palette = context.palette;
    final today = DateUtils.dateOnly(DateTime.now());
    final daysInMonth = DateUtils.getDaysInMonth(_month.year, _month.month);
    // 월요일부터 시작한다: 1일 앞에 비는 칸 수.
    final lead = DateTime(_month.year, _month.month).weekday - 1;
    final cells = lead + daysInMonth;
    final rows = (cells / 7).ceil();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _header(context),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: Text(
                    _weekdays[i],
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: palette.muted,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (var r = 0; r < rows; r++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: _dayCell(
                    context,
                    r * 7 + col - lead + 1,
                    daysInMonth,
                    today,
                    col,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _dayCell(
    BuildContext context,
    int day,
    int daysInMonth,
    DateTime today,
    int col,
  ) {
    if (day < 1 || day > daysInMonth) return const SizedBox(height: 44);
    final palette = context.palette;
    final date = DateTime(_month.year, _month.month, day);
    final enabled = _enabled(date);
    final selected = DateUtils.isSameDay(date, _selected);
    final isToday = DateUtils.isSameDay(date, today);
    // 배색은 잉크색 하나: 고른 날은 잉크색 칸에 반전 글자, 오늘은 잉크색 테두리.
    final color = !enabled
        ? palette.muted.withValues(alpha: 0.35)
        : selected
        ? palette.surface
        : palette.ink;
    return Padding(
      padding: const EdgeInsets.all(2),
      child: InkWell(
        borderRadius: AppField.radius,
        onTap: enabled ? () => setState(() => _selected = date) : null,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? palette.ink : null,
            borderRadius: AppField.radius,
            border: !selected && isToday
                ? Border.all(color: palette.ink, width: 1.2)
                : null,
          ),
          child: Text(
            '$day',
            style: TextStyle(
              color: color,
              fontWeight: selected || isToday
                  ? FontWeight.w800
                  : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  /// 해를 넘기며 달을 바로 고르는 화면.
  Widget _monthPicker(BuildContext context) {
    final palette = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: '이전 해',
              visualDensity: VisualDensity.compact,
              onPressed: _year > widget.first.year
                  ? () => setState(() => _year--)
                  : null,
              icon: const Icon(AppIcons.caretLeft, size: 18),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '$_year년',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: '다음 해',
              visualDensity: VisualDensity.compact,
              onPressed: _year < widget.last.year
                  ? () => setState(() => _year++)
                  : null,
              icon: const Icon(AppIcons.caretRight, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.7,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          children: [
            for (var m = 1; m <= 12; m++)
              InkWell(
                borderRadius: AppField.radius,
                onTap: _monthEnabled(_year, m)
                    ? () => setState(() {
                        _month = DateTime(_year, m);
                        _pickingMonth = false;
                      })
                    : null,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _month.year == _year && _month.month == m
                        ? palette.brand
                        : null,
                    borderRadius: AppField.radius,
                    border: Border.all(
                      color: _month.year == _year && _month.month == m
                          ? palette.brand
                          : palette.border,
                    ),
                  ),
                  child: Text(
                    '$m월',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: !_monthEnabled(_year, m)
                          ? palette.muted.withValues(alpha: 0.35)
                          : (_month.year == _year && _month.month == m
                                ? palette.onBrand
                                : palette.ink),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// 앱 전용 시각 고르기. 달력과 같은 모양의 칸을 눌러 고른다: 오전 / 오후, 시(1~12), 분(5분 단위 + 1분 조절).
/// 고른 칸은 달력의 고른 날처럼 잉크색 칸에 반전 글자이고, 지금 시각의 칸은 잉크색 테두리다.
/// 모든 글자가 한글이다. 닫으면 null.
Future<TimeOfDay?> showAppTimePicker(
  BuildContext context, {
  required TimeOfDay initialTime,
  String title = '시각 선택',
}) => showDialog<TimeOfDay>(
  context: context,
  builder: (_) => Dialog(
    insetPadding: const EdgeInsets.all(16),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: _TimePickerBody(initial: initialTime, title: title),
    ),
  ),
);

class _TimePickerBody extends StatefulWidget {
  const _TimePickerBody({required this.initial, required this.title});

  final TimeOfDay initial;
  final String title;

  @override
  State<_TimePickerBody> createState() => _TimePickerBodyState();
}

class _TimePickerBodyState extends State<_TimePickerBody> {
  late bool _pm = widget.initial.hour >= 12;

  /// 1~12.
  late int _hour12 = widget.initial.hour % 12 == 0
      ? 12
      : widget.initial.hour % 12;
  late int _minute = widget.initial.minute;

  TimeOfDay get _value =>
      TimeOfDay(hour: (_hour12 % 12) + (_pm ? 12 : 0), minute: _minute);

  /// 달력의 날 칸과 같은 모양의 칸 하나. [selected]는 잉크색 칸, [ring]은 잉크색 테두리.
  Widget _cell(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool ring = false,
  }) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.all(2),
      child: InkWell(
        borderRadius: AppField.radius,
        onTap: onTap,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? palette.ink : null,
            borderRadius: AppField.radius,
            border: !selected && ring
                ? Border.all(color: palette.ink, width: 1.2)
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? palette.surface : palette.ink,
              fontWeight: selected || ring ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  /// 칸 여러 개를 [columns]열로 늘어놓는다.
  Widget _grid(int columns, List<Widget> cells) {
    final rows = (cells.length / columns).ceil();
    return Column(
      children: [
        for (var r = 0; r < rows; r++)
          Row(
            children: [
              for (var c = 0; c < columns; c++)
                Expanded(
                  child: r * columns + c < cells.length
                      ? cells[r * columns + c]
                      : const SizedBox(),
                ),
            ],
          ),
      ],
    );
  }

  Widget _label(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(left: 4, top: 12, bottom: 4),
    child: Text(
      text,
      style: TextStyle(
        color: context.palette.muted,
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  void _step(int delta) => setState(() {
    final total = (_minute + delta) % 60;
    _minute = total < 0 ? total + 60 : total;
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final t = _value;
    final now = TimeOfDay.now();
    final nowPm = now.hour >= 12;
    final nowHour12 = now.hour % 12 == 0 ? 12 : now.hour % 12;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            style: TextStyle(
              color: palette.muted,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${t.hour < 12 ? '오전' : '오후'} ${t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod}시 ${t.minute}분',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: palette.border),
          // 오전 / 오후
          _grid(2, [
            _cell(
              context,
              label: '오전',
              selected: !_pm,
              ring: !nowPm,
              onTap: () => setState(() => _pm = false),
            ),
            _cell(
              context,
              label: '오후',
              selected: _pm,
              ring: nowPm,
              onTap: () => setState(() => _pm = true),
            ),
          ]),
          // 시와 분이 나란히 있다.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _label(context, '시'),
                    _grid(3, [
                      for (var h = 1; h <= 12; h++)
                        _cell(
                          context,
                          label: '$h',
                          selected: _hour12 == h,
                          ring: nowPm == _pm && nowHour12 == h,
                          onTap: () => setState(() => _hour12 = h),
                        ),
                    ]),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 200,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: palette.border,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _label(context, '분'),
                    _grid(3, [
                      for (var m = 0; m < 60; m += 5)
                        _cell(
                          context,
                          label: m.toString().padLeft(2, '0'),
                          selected: _minute == m,
                          onTap: () => setState(() => _minute = m),
                        ),
                    ]),
                    // 1분 조절
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          tooltip: '1분 전',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _step(-1),
                          icon: const Icon(AppIcons.caretLeft, size: 18),
                        ),
                        SizedBox(
                          width: 44,
                          child: Center(
                            child: Text(
                              '${_minute.toString().padLeft(2, '0')}분',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: '1분 후',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _step(1),
                          icon: const Icon(AppIcons.caretRight, size: 18),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: () => setState(() {
                  _pm = now.hour >= 12;
                  _hour12 = nowHour12;
                  _minute = now.minute;
                }),
                child: const Text('지금'),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              const SizedBox(width: 4),
              FilledButton(
                onPressed: () => Navigator.pop(context, _value),
                child: const Text('확인'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
