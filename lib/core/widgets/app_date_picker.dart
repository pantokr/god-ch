import 'dart:math' as math;

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

/// 앱 전용 시각 고르기: 흔한 아날로그 시계판을 돌려 고른다.
/// - 맨 위의 큰 "시 : 분" 숫자를 누르면 시계판이 시 / 분으로 바뀐다 (시를 고르면 바로 분으로 넘어간다).
/// - 시계판의 숫자를 누르거나 바늘 끝을 끌어서 고르고, 분은 1분 단위로 맞춘다.
/// - 고른 값은 잉크색 둥근 표식과 바늘로 보이고, 오전 / 오후는 오른쪽 두 칸에서 고른다.
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

  /// true이면 시계판이 분을 고른다.
  bool _minuteMode = false;

  TimeOfDay get _value =>
      TimeOfDay(hour: (_hour12 % 12) + (_pm ? 12 : 0), minute: _minute);

  /// 큰 숫자 한 칸: 고른 쪽은 잉크색 칸에 반전 글자.
  Widget _digit(String text, {required bool selected, VoidCallback? onTap}) {
    final palette = context.palette;
    return InkWell(
      borderRadius: AppField.radius,
      onTap: onTap,
      child: Container(
        width: 72,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? palette.ink : palette.ink.withValues(alpha: 0.06),
          borderRadius: AppField.radius,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: selected ? palette.surface : palette.ink,
          ),
        ),
      ),
    );
  }

  Widget _period(String label, {required bool selected}) {
    final palette = context.palette;
    return InkWell(
      borderRadius: AppField.radius,
      onTap: () => setState(() => _pm = label == '오후'),
      child: Container(
        width: 56,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? palette.ink : null,
          borderRadius: AppField.radius,
          border: selected ? null : Border.all(color: palette.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: selected ? palette.surface : palette.muted,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final now = TimeOfDay.now();
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
          const SizedBox(height: 12),
          // 큰 "시 : 분"과 오전 / 오후.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _digit(
                '$_hour12',
                selected: !_minuteMode,
                onTap: () => setState(() => _minuteMode = false),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  ':',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: palette.ink,
                  ),
                ),
              ),
              _digit(
                _minute.toString().padLeft(2, '0'),
                selected: _minuteMode,
                onTap: () => setState(() => _minuteMode = true),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _period('오전', selected: !_pm),
                  const SizedBox(height: 4),
                  _period('오후', selected: _pm),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 시계판: 시는 1~12, 분은 0~59.
          Center(
            child: _ClockDial(
              minuteMode: _minuteMode,
              value: _minuteMode ? _minute : _hour12,
              onChanged: (v) => setState(() {
                if (_minuteMode) {
                  _minute = v;
                } else {
                  _hour12 = v;
                }
              }),
              // 시를 고르고 손을 떼면 분으로 넘어간다.
              onEnd: () {
                if (!_minuteMode) setState(() => _minuteMode = true);
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: () => setState(() {
                  _pm = now.hour >= 12;
                  _hour12 = now.hour % 12 == 0 ? 12 : now.hour % 12;
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

/// 둥근 시계판. 눌러서 또는 끌어서 시(1~12) / 분(0~59)을 고른다.
class _ClockDial extends StatelessWidget {
  const _ClockDial({
    required this.minuteMode,
    required this.value,
    required this.onChanged,
    required this.onEnd,
  });

  static const double size = 248;

  final bool minuteMode;
  final int value;
  final ValueChanged<int> onChanged;
  final VoidCallback onEnd;

  /// 눌린 자리(시계판 좌표)를 값으로 바꾼다: 위쪽이 12시 / 0분, 시계 방향.
  void _pick(Offset p) {
    const c = size / 2;
    var angle = math.atan2(p.dx - c, -(p.dy - c));
    if (angle < 0) angle += 2 * math.pi;
    if (minuteMode) {
      onChanged((angle / (2 * math.pi) * 60).round() % 60);
    } else {
      final h = (angle / (2 * math.pi) * 12).round() % 12;
      onChanged(h == 0 ? 12 : h);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      onPanDown: (d) => _pick(d.localPosition),
      onPanUpdate: (d) => _pick(d.localPosition),
      onPanEnd: (_) => onEnd(),
      onTapUp: (d) {
        _pick(d.localPosition);
        onEnd();
      },
      child: CustomPaint(
        size: const Size(size, size),
        painter: _ClockPainter(
          minuteMode: minuteMode,
          value: value,
          ink: palette.ink,
          onInk: palette.surface,
          muted: palette.muted,
        ),
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  _ClockPainter({
    required this.minuteMode,
    required this.value,
    required this.ink,
    required this.onInk,
    required this.muted,
  });

  final bool minuteMode;
  final int value;
  final Color ink;
  final Color onInk;
  final Color muted;

  /// 시계판 가운데에서 [angle](위쪽 0, 시계 방향) 방향으로 [radius]만큼 간 자리.
  Offset _at(Offset c, double angle, double radius) =>
      c + Offset(math.sin(angle) * radius, -math.cos(angle) * radius);

  void _text(
    Canvas canvas,
    String text,
    Offset center,
    Color color,
    FontWeight weight,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: 16, fontWeight: weight, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final labelRadius = r - 28;

    // 바탕: 옅은 원과 얇은 테두리.
    canvas.drawCircle(c, r, Paint()..color = ink.withValues(alpha: 0.06));
    canvas.drawCircle(
      c,
      r - 0.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = ink.withValues(alpha: 0.12),
    );

    // 분 눈금: 분 화면에서만 1분마다 작은 점.
    if (minuteMode) {
      final dot = Paint()..color = muted.withValues(alpha: 0.45);
      for (var i = 0; i < 60; i++) {
        if (i % 5 == 0) continue;
        canvas.drawCircle(_at(c, i * math.pi / 30, r - 8), 1.2, dot);
      }
    }

    // 바늘과 표식.
    final angle = minuteMode
        ? value * math.pi / 30
        : (value % 12) * math.pi / 6;
    final tip = _at(c, angle, labelRadius);
    canvas.drawLine(
      c,
      tip,
      Paint()
        ..color = ink
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(c, 4.5, Paint()..color = ink);
    canvas.drawCircle(tip, 20, Paint()..color = ink);

    // 숫자: 시는 1~12, 분은 5분마다. 고른 숫자는 표식 위에서 반전 글자.
    final onLabel = minuteMode ? value % 5 == 0 : true;
    for (var i = 0; i < 12; i++) {
      final shown = minuteMode ? i * 5 : (i == 0 ? 12 : i);
      final selected = onLabel && shown == (minuteMode ? value : value);
      _text(
        canvas,
        '$shown',
        _at(c, i * math.pi / 6, labelRadius),
        selected ? onInk : ink,
        selected ? FontWeight.w800 : FontWeight.w500,
      );
    }
    // 5분 눈금 사이를 고른 분은 표식 안에 숫자로 보인다.
    if (minuteMode && !onLabel) {
      _text(canvas, '$value', tip, onInk, FontWeight.w800);
    }
  }

  @override
  bool shouldRepaint(_ClockPainter old) =>
      old.minuteMode != minuteMode ||
      old.value != value ||
      old.ink != ink ||
      old.onInk != onInk ||
      old.muted != muted;
}
