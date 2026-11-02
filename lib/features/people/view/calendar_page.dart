import 'package:flutter/material.dart';

import '../../../core/layout/responsive.dart';

import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/icons.dart';
import '../../../core/layout/page_frame.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/thumbnail_avatar.dart';
import '../../../data/models/meeting.dart';
import '../../../data/models/member.dart';
import '../../../data/models/person_card.dart';
import '../../home/view/content_widgets.dart';
import '../../meetings/view/meeting_format.dart';

/// 달력: 이번 달 모임 일정과 생일을 한 달력에 모아 본다. 날짜를 누르면 그날의 모임과 생일이 아래에 나온다.
/// 생일은 같은 소속의 사람과 나만 보이고, 교역자 이상은 모든 사람이 보인다 (월-일만 쓰고 출생 연도는 쓰지 않는다).
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key, required this.me});

  final Member me;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late final Stream<List<Meeting>> _meetings = AppScope.read(context).meetings
      .latest(widget.me.churchId, limit: 300);
  late final Stream<List<PersonCard>> _people = AppScope.read(context).people
      .people(widget.me.churchId);

  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late DateTime _selected = _today;

  static DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static const _weekdays = ['일', '월', '화', '수', '목', '금', '토'];

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// 이 사람의 생일을 볼 수 있는가: 나, 같은 소속, 교역자 이상.
  bool _canSeeBirthday(PersonCard p) {
    final me = widget.me;
    if (p.id == me.id || me.isStaff || me.isAdmin || me.isOperatorView) {
      return true;
    }
    return p.affiliationIds.any(me.affiliationIds.contains);
  }

  void _moveMonth(int delta) => setState(() {
    _month = DateTime(_month.year, _month.month + delta);
    // 달을 옮기면 그 달의 같은 날(없으면 1일)을 고른다.
    _selected = DateTime(_month.year, _month.month, 1);
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: PageFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageTitle(
              gap: 24,
              title: '',
              description: '모임 일정과 생일을 한 달력에 모았습니다. 날짜를 누르면 그날을 봅니다.',
            ),
            StreamBuilder<List<Meeting>>(
              stream: _meetings,
              builder: (context, meetSnap) => StreamBuilder<List<PersonCard>>(
                stream: _people,
                builder: (context, peopleSnap) {
                  if (meetSnap.hasError) {
                    return EmptyHint(
                      '불러오지 못했습니다${String.fromCharCode(10)}${meetSnap.error}',
                    );
                  }
                  if (!meetSnap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: AppLoader()),
                    );
                  }
                  final meetings = meetSnap.data!;
                  final people = [
                    for (final p in peopleSnap.data ?? const <PersonCard>[])
                      if (p.birthMonthDay.isNotEmpty && _canSeeBirthday(p)) p,
                  ];
                  return _body(context, meetings, people);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 달력 칸 배치: 한 줄 높이와 날짜 칸 크기.
  static const _rowPitch = 50.0;
  static const _cellSize = 38.0;

  Widget _body(
    BuildContext context,
    List<Meeting> meetings,
    List<PersonCard> people,
  ) {
    final palette = context.palette;
    final daysInMonth = DateUtils.getDaysInMonth(_month.year, _month.month);
    // 일요일 시작: DateTime.weekday는 월=1 … 일=7 이라 일요일을 0으로 맞춘다.
    final lead = DateTime(_month.year, _month.month, 1).weekday % 7;
    final rows = ((lead + daysInMonth) / 7).ceil();
    bool meetingOn(int d) => meetings.any(
      (m) => _sameDay(m.date, DateTime(_month.year, _month.month, d)),
    );
    bool birthdayOn(int d) =>
        people.any((p) => p.birthMonth == _month.month && p.birthDay == d);
    final dayMeetings = [
      for (final m in meetings)
        if (_sameDay(m.date, _selected)) m,
    ]..sort((a, b) => a.date.compareTo(b.date));
    final dayBirthdays = [
      for (final p in people)
        if (p.birthMonth == _selected.month && p.birthDay == _selected.day) p,
    ]..sort((a, b) => a.name.compareTo(b.name));

    // 배색은 글자색(잉크) 하나에 강조색 하나뿐이다. 요일 색을 나누지 않는다.
    // 선택한 날은 잉크색으로 채운 칸(입력칸과 같은 모서리), 오늘은 잉크색 테두리 칸,
    // 모임이 있는 날은 숫자 아래 강조색 점, 생일이 있는 날은 속이 빈 점이다.
    Widget cell(int day) {
      if (day < 1 || day > daysInMonth) return const SizedBox.shrink();
      final date = DateTime(_month.year, _month.month, day);
      final hasMeeting = meetingOn(day);
      final hasBirthday = birthdayOn(day);
      final isToday = _sameDay(date, _today);
      final isSelected = _sameDay(date, _selected);
      final dotColor = isSelected ? palette.surface : palette.brand;
      return Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: InkResponse(
            onTap: () => setState(() => _selected = date),
            radius: _cellSize / 2 + 4,
            child: Container(
              width: _cellSize,
              height: _cellSize + 6,
              decoration: BoxDecoration(
                color: isSelected ? palette.ink : null,
                borderRadius: AppField.radius,
                border: !isSelected && isToday
                    ? Border.all(color: palette.ink, width: 1.2)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected || isToday
                          ? FontWeight.w800
                          : FontWeight.w500,
                      color: isSelected ? palette.surface : palette.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  SizedBox(
                    height: 5,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasMeeting)
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: dotColor,
                            ),
                          ),
                        if (hasMeeting && hasBirthday) const SizedBox(width: 3),
                        if (hasBirthday)
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? palette.surface
                                    : palette.muted,
                                width: 1,
                              ),
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

    // 큰 달 숫자 + 작은 연도, 오른쪽에 이동 화살표. 달력 부분만 흰 바탕이다 (어두운 모드에서는 카드 바탕색).
    final calendar = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${_month.month}월',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${_month.year}',
                style: TextStyle(
                  color: palette.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: '이전 달',
              visualDensity: VisualDensity.compact,
              icon: const Icon(AppIcons.caretLeft),
              onPressed: () => _moveMonth(-1),
            ),
            IconButton(
              tooltip: '다음 달',
              visualDensity: VisualDensity.compact,
              icon: const Icon(AppIcons.caretRight),
              onPressed: () => _moveMonth(1),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: Text(
                    _weekdays[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: palette.muted,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Divider(height: 1, color: palette.border),
        for (var r = 0; r < rows; r++)
          SizedBox(
            height: _rowPitch,
            child: Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(child: cell(r * 7 + c - lead + 1)),
              ],
            ),
          ),
        Divider(height: 1, color: palette.border),
      ],
    );
    final panel = Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: calendar,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        panel,
        const SizedBox(height: 14),
        Gutter(
          child: Row(
            children: [
              _Legend(color: palette.brand, label: '모임'),
              const SizedBox(width: 16),
              _Legend(color: palette.muted, label: '생일', hollow: true),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Gutter(
          child: Text(
            '${_selected.month}월 ${_selected.day}일 ${_weekdays[_selected.weekday % 7]}요일',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ),
        const SizedBox(height: 8),
        if (dayMeetings.isEmpty && dayBirthdays.isEmpty)
          EmptyHint('일정 없음')
        else ...[
          for (final m in dayMeetings)
            _Bubble(
              color: palette.brand,
              label: '모임',
              title: m.title,
              sub: [
                meetingWhen(m.date),
                if (m.place.isNotEmpty) m.place,
              ].join(' · '),
              onTap: () =>
                  context.push(Routes.meeting(widget.me.churchId, m.id)),
            ),
          for (final p in dayBirthdays)
            _Bubble(
              color: palette.muted,
              label: '생일',
              title: p.name,
              sub: '${_selected.month}월 ${_selected.day}일',
              leading: ThumbnailAvatar(name: p.name, url: p.photoUrl),
            ),
        ],
      ],
    );
  }
}

/// 달력 아래 범례 한 칸: 모임은 채운 점, 생일은 속이 빈 점.
class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.label,
    this.hollow = false,
  });

  final Color color;
  final String label;
  final bool hollow;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: hollow ? null : color,
          border: hollow ? Border.all(color: color, width: 1.2) : null,
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(color: context.palette.muted, fontSize: 12)),
    ],
  );
}

/// 그날의 모임 · 생일 한 줄: 상자 없이 왼쪽의 가는 세로선 하나(모임은 강조색, 생일은 회색). 모임은 누르면 상세 화면이 열린다.
class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.color,
    required this.label,
    required this.title,
    required this.sub,
    this.onTap,
    this.leading,
  });

  final Color color;
  final String label;
  final String title;
  final String sub;
  final VoidCallback? onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: textGutter(context),
          vertical: 8,
        ),
        child: Container(
          padding: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 2)),
          ),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 12)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.muted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                    if (sub.isNotEmpty)
                      Text(
                        sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: palette.muted, fontSize: 12.5),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
