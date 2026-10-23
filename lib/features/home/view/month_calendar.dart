import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../data/models/church_content.dart';
import 'content_widgets.dart';

/// 이번 달 달력. 일정이 있는 날짜에 동그라미를 치고, 날짜를 누르면(일정이 없는 날도 가능)
/// 달력 옆의 사각형 말풍선에 그날의 일정 요약만 보여준다. 말풍선을 누르면 상세 화면이 열린다.
/// 좁은 화면에서는 같은 동그라미 날짜를 붙인 말풍선을 달력 아래에 둔다.
class MonthCalendar extends StatefulWidget {
  const MonthCalendar({
    super.key,
    required this.events,
    required this.onOpen,
    this.hint = '',
  });

  final List<ChurchContent> events;
  final void Function(ChurchContent) onOpen;
  final String hint;

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();

  static const _weekdays = ['일', '월', '화', '수', '목', '금', '토'];

  // 달력 칸 배치(고정 값): 말풍선과 잇는 선의 좌표를 계산하는 데 쓴다.
  static const _pad = 12.0;
  static const _gridTop = 78.0;
  static const _rowPitch = 52.0;
  static const _circle = 36.0;
  static const _bubbleHeight = 76.0;
  static const _bubbleGap = 8.0;
  static const _wideBreak = 640.0;
}

class _MonthCalendarState extends State<MonthCalendar> {
  static const _pad = MonthCalendar._pad;
  static const _gridTop = MonthCalendar._gridTop;
  static const _rowPitch = MonthCalendar._rowPitch;
  static const _bubbleHeight = MonthCalendar._bubbleHeight;
  static const _bubbleGap = MonthCalendar._bubbleGap;
  static const _wideBreak = MonthCalendar._wideBreak;

  /// 누른 날짜(일). 일정이 없는 날짜도 골라서 그날 일정이 없음을 볼 수 있다.
  int? _selected;

  /// 이번 달 일정만 달력에 나타낸다.
  List<ChurchContent> get _monthEvents {
    final now = DateTime.now();
    return [
      for (final e in widget.events)
        if (e.date.year == now.year && e.date.month == now.month) e,
    ];
  }

  /// 처음에는 오늘 이후 가장 가까운 일정 날짜(오늘 일정이 있으면 오늘)를 보여준다.
  /// 이번 달에 일정이 없으면 오늘.
  int _defaultDay(List<ChurchContent> events) {
    final today = DateTime.now().day;
    if (events.isEmpty) return today;
    final days = {for (final e in events) e.date.day}.toList()..sort();
    return days.firstWhere((d) => d >= today, orElse: () => days.last);
  }

  @override
  Widget build(BuildContext context) {
    final onOpen = widget.onOpen;
    final hint = widget.hint;
    final events = _monthEvents;
    final dated = {for (final e in events) e.date.day};
    final selected = _selected ?? _defaultDay(events);
    final now = DateTime.now();
    final noEvent = '${now.month}월 $selected일에는 일정이 없어요.$hint';
    // 말풍선에는 누른 날짜의 일정만 나온다.
    final shown = [
      for (final e in events)
        if (e.date.day == selected) e,
    ];

    final today = DateTime.now();
    final first = DateTime(today.year, today.month);
    final days = DateUtils.getDaysInMonth(first.year, first.month);
    final lead = first.weekday % 7; // 일요일 시작 (DateTime.weekday: 월=1 … 일=7)
    final rows = ((lead + days) / 7).ceil();
    final calendarHeight = _gridTop + rows * _rowPitch + _pad;

    Widget calendar(double width) => _CalendarCard(
      width: width,
      height: calendarHeight,
      first: first,
      lead: lead,
      days: days,
      rows: rows,
      today: today.day,
      dated: dated,
      selected: selected,
      onSelect: (d) => setState(() => _selected = d),
    );

    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= _wideBreak;
        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              calendar(box.maxWidth),
              const SizedBox(height: 12),
              if (shown.isEmpty)
                EmptyHint(noEvent)
              else
                for (final e in shown)
                  Padding(
                    padding: const EdgeInsets.only(bottom: _bubbleGap),
                    child: Row(
                      children: [
                        _DayCircle(day: e.date.day),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _Bubble(event: e, onTap: () => onOpen(e)),
                        ),
                      ],
                    ),
                  ),
            ],
          );
        }

        // 왼쪽에 달력, 오른쪽에 누른 날짜의 말풍선을 달력 첫 줄 높이부터 쌓는다.
        final cw = box.maxWidth * 0.56;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            calendar(cw),
            const SizedBox(width: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: _gridTop),
                child: shown.isEmpty
                    ? EmptyHint(noEvent)
                    : Column(
                        children: [
                          for (final e in shown)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: _bubbleGap,
                              ),
                              child: SizedBox(
                                height: _bubbleHeight,
                                child: _Bubble(
                                  event: e,
                                  onTap: () => onOpen(e),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.width,
    required this.height,
    required this.first,
    required this.lead,
    required this.days,
    required this.rows,
    required this.today,
    required this.dated,
    required this.selected,
    required this.onSelect,
  });

  final double width;
  final double height;
  final DateTime first;
  final int lead;
  final int days;
  final int rows;
  final int today;
  final Set<int> dated;
  final int? selected;
  final void Function(int day) onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final error = Theme.of(context).colorScheme.error;
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.fromLTRB(
        MonthCalendar._pad,
        16,
        MonthCalendar._pad,
        0,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 24,
            child: Center(
              child: Text(
                '${first.year}년 ${first.month}월',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 20,
            child: Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Center(
                      child: Text(
                        MonthCalendar._weekdays[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: i == 0 ? error : palette.muted,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          for (var r = 0; r < rows; r++)
            SizedBox(
              height: MonthCalendar._rowPitch,
              child: Row(
                children: [
                  for (var c = 0; c < 7; c++)
                    Expanded(child: _cell(context, r * 7 + c - lead + 1, c)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _cell(BuildContext context, int day, int col) {
    if (day < 1 || day > days) return const SizedBox.shrink();
    final palette = context.palette;
    final hasEvent = dated.contains(day);
    final isToday = day == today;
    final isSelected = day == selected;
    final circle = Container(
      width: MonthCalendar._circle,
      height: MonthCalendar._circle,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? palette.brand
            : isToday
            ? palette.accent.withValues(alpha: 0.22)
            : null,
        border: hasEvent ? Border.all(color: palette.brand, width: 2) : null,
      ),
      child: Text(
        '$day',
        style: TextStyle(
          fontWeight: hasEvent || isToday ? FontWeight.w700 : FontWeight.w500,
          color: isSelected
              ? palette.onBrand
              : hasEvent
              ? palette.brand
              : col == 0
              ? Theme.of(context).colorScheme.error
              : palette.ink,
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 6),
          // 모든 날짜를 눌러 그날의 일정을 조회할 수 있다.
          child: InkResponse(
            onTap: () => onSelect(day),
            radius: MonthCalendar._circle / 2 + 4,
            child: circle,
          ),
        ),
      ),
    );
  }
}

/// 좁은 화면에서 말풍선 옆에 붙는 동그라미 날짜.
class _DayCircle extends StatelessWidget {
  const _DayCircle({required this.day});

  final int day;

  @override
  Widget build(BuildContext context) {
    final brand = context.palette.brand;
    return Container(
      width: MonthCalendar._circle,
      height: MonthCalendar._circle,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: brand, width: 2),
      ),
      child: Text(
        '$day',
        style: TextStyle(color: brand, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// 일정 요약 말풍선(사각형). 누르면 상세 화면.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.event, required this.onTap});

  final ChurchContent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final d = event.date;
    final summary = event.body.split('\n').first;
    final radius = BorderRadius.circular(AppRadius.card);
    return Material(
      color: palette.surface,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: palette.brand.withValues(alpha: 0.45)),
            borderRadius: radius,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${d.month}월 ${d.day}일 ${weekdayLabel(d)}요일',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.accent,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                event.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              if (summary.isNotEmpty)
                Text(
                  summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: palette.muted, fontSize: 12.5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
