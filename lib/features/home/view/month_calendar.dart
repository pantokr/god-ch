import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../data/models/church_content.dart';
import 'content_widgets.dart';

/// 달력 한 가지 모양의 색 구성. 달력 디자인마다 하나씩 있다.
/// 네온·선셋은 라이트·다크에서 같은 색을 쓴다 (원래 어두운 색이라 다크 모드에도 어울린다).
/// 기본(paper)은 앱 테마를 따르고, 흑백 포스터·파스텔은 다크 모드에서 어두운 짝(`_monoDark`, `_pastelDark`)을 쓴다.
@immutable
class CalendarStyle {
  const CalendarStyle({
    required this.body,
    required this.header,
    required this.headerText,
    required this.weekday,
    required this.sunday,
    required this.text,
    required this.eventText,
    required this.selected,
    required this.selectedText,
    required this.glow,
    required this.today,
    required this.dot,
    required this.bubble,
    required this.bubbleBar,
    required this.bubbleDate,
    required this.bubbleTitle,
    required this.bubbleSub,
    this.border,
  });

  /// 달력 몸통 배경.
  final Gradient body;

  /// 위쪽 "n월" 띠 배경과 그 위 글자색.
  final Gradient header;
  final Color headerText;

  /// 요일 글자 · 일요일 · 보통 날짜 · 일정이 있는 날 숫자 색.
  final Color weekday;
  final Color sunday;
  final Color text;
  final Color eventText;

  /// 선택한 날의 원 · 그 위 숫자 · 빛 번짐.
  final Gradient selected;
  final Color selectedText;
  final Color glow;

  /// 오늘 표시와 일정 점.
  final Color today;
  final Color dot;

  /// 말풍선 배경 · 왼쪽 띠 · 날짜 · 제목 · 설명 색.
  final Color bubble;
  final Gradient bubbleBar;
  final Color bubbleDate;
  final Color bubbleTitle;
  final Color bubbleSub;

  /// 달력 카드와 말풍선의 테두리 (없으면 그림자만).
  final Color? border;

  /// 디자인 id → 색 구성. 모르는 id는 기본(paper)이다.
  static CalendarStyle of(String variant, BuildContext context) =>
      switch (variant) {
        'calendar' => _neon,
        'calendar_sunset' => _sunset,
        'calendar_mono' =>
          Theme.of(context).brightness == Brightness.dark ? _monoDark : _mono,
        'calendar_pastel' =>
          Theme.of(context).brightness == Brightness.dark
              ? _pastelDark
              : _pastel,
        _ => _paper(context),
      };

  /// 깊은 보라 밤하늘 + 라임 + 핫핑크.
  static const _neon = CalendarStyle(
    body: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF14121F), Color(0xFF241C45)],
    ),
    header: LinearGradient(colors: [Color(0xFFC6FF3D), Color(0xFF6EF3C5)]),
    headerText: Color(0xFF14121F),
    weekday: Color(0xFF9D97C9),
    sunday: Color(0xFFFF4F8B),
    text: Color(0xFFF1EEFF),
    eventText: Color(0xFFC6FF3D),
    selected: LinearGradient(colors: [Color(0xFFC6FF3D), Color(0xFF6EF3C5)]),
    selectedText: Color(0xFF14121F),
    glow: Color(0xFFC6FF3D),
    today: Color(0xFFFF4F8B),
    dot: Color(0xFFFF4F8B),
    bubble: Color(0xFF241C45),
    bubbleBar: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFC6FF3D), Color(0xFFFF4F8B)],
    ),
    bubbleDate: Color(0xFFC6FF3D),
    bubbleTitle: Color(0xFFF1EEFF),
    bubbleSub: Color(0xFF9D97C9),
  );

  /// 노을: 자주 → 주황 → 노랑으로 번지는 따뜻한 하늘.
  static const _sunset = CalendarStyle(
    body: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF3B1C5A), Color(0xFFB8336A), Color(0xFFFF8A4C)],
    ),
    header: LinearGradient(colors: [Color(0xFFFFD36B), Color(0xFFFF9A5A)]),
    headerText: Color(0xFF3B1C5A),
    weekday: Color(0xFFFFE3C9),
    sunday: Color(0xFFFFE066),
    text: Color(0xFFFFFFFF),
    eventText: Color(0xFFFFE066),
    selected: LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFFFE9C7)]),
    selectedText: Color(0xFFB8336A),
    glow: Color(0xFFFFFFFF),
    today: Color(0xFFFFE066),
    dot: Color(0xFFFFE066),
    bubble: Color(0xFF4A1F62),
    bubbleBar: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFD36B), Color(0xFFFF6B6B)],
    ),
    bubbleDate: Color(0xFFFFD36B),
    bubbleTitle: Color(0xFFFFFFFF),
    bubbleSub: Color(0xFFFFD9C2),
  );

  /// 흑백 + 노랑: 굵은 검은 테두리의 포스터 느낌.
  static const _mono = CalendarStyle(
    body: LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)]),
    header: LinearGradient(colors: [Color(0xFF111111), Color(0xFF111111)]),
    headerText: Color(0xFFFFE600),
    weekday: Color(0xFF111111),
    sunday: Color(0xFFE5002B),
    text: Color(0xFF111111),
    eventText: Color(0xFF111111),
    selected: LinearGradient(colors: [Color(0xFFFFE600), Color(0xFFFFE600)]),
    selectedText: Color(0xFF111111),
    glow: Color(0xFF111111),
    today: Color(0xFF111111),
    dot: Color(0xFFE5002B),
    bubble: Color(0xFFFFE600),
    bubbleBar: LinearGradient(colors: [Color(0xFF111111), Color(0xFF111111)]),
    bubbleDate: Color(0xFF111111),
    bubbleTitle: Color(0xFF111111),
    bubbleSub: Color(0xFF3A3A3A),
    border: Color(0xFF111111),
  );

  /// 흑백 포스터의 다크 모드: 검정 바탕에 흰 테두리, 노랑 포인트는 그대로 두고 색을 뒤집는다.
  static const _monoDark = CalendarStyle(
    body: LinearGradient(colors: [Color(0xFF111111), Color(0xFF111111)]),
    header: LinearGradient(colors: [Color(0xFFFFE600), Color(0xFFFFE600)]),
    headerText: Color(0xFF111111),
    weekday: Color(0xFFF2F2F2),
    sunday: Color(0xFFFF5C7A),
    text: Color(0xFFF2F2F2),
    eventText: Color(0xFFFFE600),
    selected: LinearGradient(colors: [Color(0xFFFFE600), Color(0xFFFFE600)]),
    selectedText: Color(0xFF111111),
    glow: Color(0xFFFFE600),
    today: Color(0xFFF2F2F2),
    dot: Color(0xFFFF5C7A),
    bubble: Color(0xFFFFE600),
    bubbleBar: LinearGradient(colors: [Color(0xFF111111), Color(0xFF111111)]),
    bubbleDate: Color(0xFF111111),
    bubbleTitle: Color(0xFF111111),
    bubbleSub: Color(0xFF3A3A3A),
    border: Color(0xFFF2F2F2),
  );

  /// 파스텔의 다크 모드: 어두운 남보라 바탕에 파스텔 포인트만 남긴다.
  static const _pastelDark = CalendarStyle(
    body: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2D2640), Color(0xFF232C45), Color(0xFF1F3A38)],
    ),
    header: LinearGradient(colors: [Color(0xFFFFB5CE), Color(0xFFA9CBFF)]),
    headerText: Color(0xFF2A2946),
    weekday: Color(0xFFB9B8E0),
    sunday: Color(0xFFFF8FB3),
    text: Color(0xFFF0EFFF),
    eventText: Color(0xFFA9C0FF),
    selected: LinearGradient(colors: [Color(0xFFFF9EC0), Color(0xFF9CC2FF)]),
    selectedText: Color(0xFF2A2946),
    glow: Color(0xFF9CC2FF),
    today: Color(0xFFFF9EC0),
    dot: Color(0xFFA9C0FF),
    bubble: Color(0xFF2E2B4A),
    bubbleBar: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFF9EC0), Color(0xFF9CC2FF)],
    ),
    bubbleDate: Color(0xFFFF9EC0),
    bubbleTitle: Color(0xFFF0EFFF),
    bubbleSub: Color(0xFFB9B8E0),
  );

  /// 파스텔: 분홍·하늘·민트가 섞인 말랑한 색.
  static const _pastel = CalendarStyle(
    body: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFEEF4), Color(0xFFE9F2FF), Color(0xFFE6FBF1)],
    ),
    header: LinearGradient(colors: [Color(0xFFFFB5CE), Color(0xFFA9CBFF)]),
    headerText: Color(0xFF3B3A5C),
    weekday: Color(0xFF8A89B0),
    sunday: Color(0xFFFF6F9C),
    text: Color(0xFF3B3A5C),
    eventText: Color(0xFF5B7BEF),
    selected: LinearGradient(colors: [Color(0xFFFF9EC0), Color(0xFF9CC2FF)]),
    selectedText: Color(0xFFFFFFFF),
    glow: Color(0xFF9CC2FF),
    today: Color(0xFFFF9EC0),
    dot: Color(0xFF5B7BEF),
    bubble: Color(0xFFFFFFFF),
    bubbleBar: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFF9EC0), Color(0xFF9CC2FF)],
    ),
    bubbleDate: Color(0xFFFF6F9C),
    bubbleTitle: Color(0xFF3B3A5C),
    bubbleSub: Color(0xFF8A89B0),
  );

  /// 기본: 앱 테마의 면과 인디고를 그대로 쓴다 (다크 모드도 따라간다).
  static CalendarStyle _paper(BuildContext context) {
    final p = context.palette;
    final brand = LinearGradient(
      colors: [p.brand, Color.lerp(p.brand, p.accent, 0.45)!],
    );
    return CalendarStyle(
      body: LinearGradient(colors: [p.surface, p.surface]),
      header: brand,
      headerText: p.onBrand,
      weekday: p.muted,
      sunday: Theme.of(context).colorScheme.error,
      text: p.ink,
      eventText: p.brand,
      selected: brand,
      selectedText: p.onBrand,
      glow: p.brand,
      today: p.accent,
      dot: p.accent,
      bubble: p.surface,
      bubbleBar: brand,
      bubbleDate: p.accent,
      bubbleTitle: p.ink,
      bubbleSub: p.muted,
    );
  }
}

/// 이번 달 달력. 일정이 있는 날짜에 동그라미를 치고, 날짜를 누르면(일정이 없는 날도 가능)
/// 달력 옆의 사각형 말풍선에 그날의 일정 요약만 보여준다. 말풍선을 누르면 상세 화면이 열린다.
/// 좁은 화면에서는 같은 동그라미 날짜를 붙인 말풍선을 달력 아래에 둔다.
/// 색 구성은 [variant](블록의 디자인 id)에 따라 [CalendarStyle]이 정한다.
class MonthCalendar extends StatefulWidget {
  const MonthCalendar({
    super.key,
    required this.events,
    required this.onOpen,
    this.hint = '',
    this.variant = 'calendar_mono',
  });

  final List<ChurchContent> events;
  final void Function(ChurchContent) onOpen;
  final String hint;
  final String variant;

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();

  static const _weekdays = ['일', '월', '화', '수', '목', '금', '토'];

  // 달력 칸 배치(고정 값): 말풍선과 잇는 선의 좌표를 계산하는 데 쓴다.
  static const _pad = 12.0;
  static const _gridTop = 90.0;
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

  /// 처음에는 항상 오늘 날짜를 가리킨다 (그날 일정이 없으면 일정이 없다고 보여준다).
  int _defaultDay(List<ChurchContent> events) => DateTime.now().day;

  @override
  Widget build(BuildContext context) {
    final onOpen = widget.onOpen;
    final hint = widget.hint;
    final style = CalendarStyle.of(widget.variant, context);
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
      style: style,
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
                        _DayCircle(style: style, day: e.date.day),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _Bubble(
                            style: style,
                            event: e,
                            onTap: () => onOpen(e),
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          );
        }

        // 왼쪽에 달력, 오른쪽에 누른 날짜의 말풍선을 달력 첫 줄 높이부터 쌓는다.
        // 화면이 넓어도 달력이 너무 커지지 않게 하고, 말풍선을 달력 바로 옆에 붙여 둔다.
        // 달력은 고정 폭(최대 440px)으로 두고, 일정 박스가 나머지 너비를 모두 차지한다.
        final cw = (box.maxWidth * 0.56).clamp(0.0, 440.0);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            calendar(cw),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: _gridTop),
                child: shown.isEmpty
                    ? EmptyHint(noEvent)
                    : Column(
                        // 가로로 가득 채운다 (기본 가운데 정렬이면 글자 폭만큼만 좁아진다).
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final e in shown)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: _bubbleGap,
                              ),
                              child: SizedBox(
                                height: _bubbleHeight,
                                child: _Bubble(
                                  style: style,
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
    required this.style,
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

  final CalendarStyle style;
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
    final radius = BorderRadius.circular(AppRadius.card + 2);
    // 떠 있는 카드: 겹친 그림자 + 위쪽의 포인트색 머리글 띠.
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: AppDepth.raised(context),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: style.border == null
                ? null
                : Border.all(color: style.border!, width: 2.5),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: style.body),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(gradient: style.header),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${first.month}월',
                        style: TextStyle(
                          color: style.headerText,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${first.year}',
                        style: TextStyle(
                          color: style.headerText.withValues(alpha: 0.65),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    MonthCalendar._pad,
                    12,
                    MonthCalendar._pad,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                                      color: i == 0
                                          ? style.sunday
                                          : style.weekday,
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
                                Expanded(child: _cell(r * 7 + c - lead + 1, c)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cell(int day, int col) {
    if (day < 1 || day > days) return const SizedBox.shrink();
    final hasEvent = dated.contains(day);
    final isToday = day == today;
    final isSelected = day == selected;
    // 선택한 날은 떠오른 포인트색 원, 오늘은 옅은 원, 일정이 있는 날은 숫자 아래 작은 점.
    final numberColor = isSelected
        ? style.selectedText
        : hasEvent
        ? style.eventText
        : col == 0
        ? style.sunday
        : style.text;
    final circle = Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: MonthCalendar._circle,
          height: MonthCalendar._circle,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isSelected ? style.selected : null,
            color: isSelected
                ? null
                : isToday
                ? style.today.withValues(alpha: 0.25)
                : null,
            border: isToday && !isSelected
                ? Border.all(color: style.today, width: 1.5)
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: style.glow.withValues(alpha: 0.5),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            '$day',
            style: TextStyle(
              fontWeight: hasEvent || isToday || isSelected
                  ? FontWeight.w800
                  : FontWeight.w500,
              color: numberColor,
            ),
          ),
        ),
        if (hasEvent)
          Positioned(
            bottom: isSelected ? 5 : 3,
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? style.selectedText : style.dot,
              ),
            ),
          ),
      ],
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

/// 좁은 화면에서 말풍선 옆에 붙는 날짜 원 (달력의 선택한 날과 같은 떠 있는 모양).
class _DayCircle extends StatelessWidget {
  const _DayCircle({required this.style, required this.day});

  final CalendarStyle style;
  final int day;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MonthCalendar._circle,
      height: MonthCalendar._circle,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: style.selected,
        border: style.border == null
            ? null
            : Border.all(color: style.border!, width: 2),
        boxShadow: [
          BoxShadow(
            color: style.glow.withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        '$day',
        style: TextStyle(
          color: style.selectedText,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// 일정 요약 카드. 왼쪽에 포인트색 띠가 있고 떠 있는 그림자를 가진다. 누르면 상세 화면.
class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.style,
    required this.event,
    required this.onTap,
  });

  final CalendarStyle style;
  final ChurchContent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = event.date;
    final summary = event.body.split('\n').first;
    final radius = BorderRadius.circular(AppRadius.card + 2);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: AppDepth.raised(context),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: style.border == null
                ? null
                : Border.all(color: style.border!, width: 2.5),
          ),
          child: Material(
            color: style.bubble,
            child: InkWell(
              onTap: onTap,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 5,
                      decoration: BoxDecoration(gradient: style.bubbleBar),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${d.month}월 ${d.day}일 ${weekdayLabel(d)}요일',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: style.bubbleDate,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                            Text(
                              event.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: style.bubbleTitle,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            if (summary.isNotEmpty)
                              Text(
                                summary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: style.bubbleSub,
                                  fontSize: 12.5,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(Icons.chevron_right, color: style.bubbleSub),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
