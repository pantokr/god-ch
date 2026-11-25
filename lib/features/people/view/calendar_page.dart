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
import 'person_popup.dart';
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

  /// 이 사람의 생일을 볼 수 있는가: 나, 같은 소속, 교역자 이상. 본인이 생일을 비공개로 했으면 본인과 교역자 이상만.
  bool _canSeeBirthday(PersonCard p) {
    final me = widget.me;
    final privileged = me.isStaff || me.isAdmin || me.isOperatorView;
    if (!p.birthShownTo(me.id, privileged: privileged)) return false;
    if (p.id == me.id || privileged) return true;
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

  /// 달력 칸 배치: 한 줄 높이.
  static const _rowPitch = 54.0;

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

    // 배색은 소프트 인디고(모임) 하나와 코랄(생일) 하나뿐이다. 요일 색을 나누지 않는다.
    // 날짜는 선 없이 둥근 칸: 선택한 날은 인디고로 채우고 옅은 그림자, 오늘은 옅은 인디고 바탕,
    // 모임이 있는 날은 숫자 아래 짧은 인디고 막대, 생일이 있는 날은 코랄 점이다.
    Widget cell(int day) {
      if (day < 1 || day > daysInMonth) return const SizedBox.shrink();
      final date = DateTime(_month.year, _month.month, day);
      final hasMeeting = meetingOn(day);
      final hasBirthday = birthdayOn(day);
      final isToday = _sameDay(date, _today);
      final isSelected = _sameDay(date, _selected);
      return Padding(
        padding: const EdgeInsets.all(3),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _selected = date),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              color: isSelected
                  ? palette.brand
                  : isToday
                  ? palette.brand.withValues(alpha: 0.12)
                  : null,
              borderRadius: BorderRadius.circular(14),
              boxShadow: isSelected ? AppShadow.soft(context) : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 15,
                    color: isSelected
                        ? palette.onBrand
                        : isToday
                        ? palette.brand
                        : palette.ink,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 5,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasMeeting)
                        Container(
                          width: 14,
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(99),
                            color: isSelected
                                ? palette.onBrand.withValues(alpha: 0.9)
                                : palette.brand,
                          ),
                        ),
                      if (hasMeeting && hasBirthday) const SizedBox(width: 3),
                      if (hasBirthday)
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? palette.onBrand.withValues(alpha: 0.9)
                                : palette.accent,
                          ),
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

    final isThisMonth =
        _month.year == _today.year && _month.month == _today.month;

    // 큰 달 숫자 + 연도 알약, 오른쪽에 오늘 · 이동 버튼 (둥근 옅은 인디고 버튼).
    final calendar = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${_month.month}월',
              style: const TextStyle(fontSize: 30, height: 1.1),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: palette.muted.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '${_month.year}',
                style: TextStyle(color: palette.muted, fontSize: 13),
              ),
            ),
            const Spacer(),
            if (!isThisMonth || !_sameDay(_selected, _today)) ...[
              _RoundButton(
                label: '오늘',
                onTap: () => setState(() {
                  _month = DateTime(_today.year, _today.month);
                  _selected = _today;
                }),
              ),
              const SizedBox(width: 8),
            ],
            _RoundButton(
              icon: AppIcons.caretLeft,
              tooltip: '이전 달',
              onTap: () => _moveMonth(-1),
            ),
            const SizedBox(width: 8),
            _RoundButton(
              icon: AppIcons.caretRight,
              tooltip: '다음 달',
              onTap: () => _moveMonth(1),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: Text(
                    _weekdays[i],
                    style: TextStyle(fontSize: 12, color: palette.muted),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
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
      ],
    );
    final panel = Container(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.panel),
        border: Border.all(color: palette.border),
        boxShadow: AppShadow.soft(context),
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
              _Legend(color: palette.brand, label: '모임', bar: true),
              const SizedBox(width: 16),
              _Legend(color: palette.accent, label: '생일'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Gutter(
          child: Text(
            '${_selected.month}월 ${_selected.day}일 ${_weekdays[_selected.weekday % 7]}요일',
            style: const TextStyle(fontSize: 15),
          ),
        ),
        const SizedBox(height: 8),
        if (dayMeetings.isEmpty && dayBirthdays.isEmpty)
          const _EmptyDay()
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
              leading: _Badge(color: palette.brand, icon: AppIcons.calendar),
              onTap: () =>
                  context.push(Routes.meeting(widget.me.churchId, m.id)),
            ),
          for (final p in dayBirthdays)
            _Bubble(
              color: palette.accent,
              label: '생일',
              title: p.name,
              sub: '${_selected.month}월 ${_selected.day}일',
              leading: ThumbnailAvatar(name: p.name, url: p.photoUrl),
              onTap: () => showPersonPopup(
                context,
                churchId: widget.me.churchId,
                uid: p.id,
                name: p.name,
                photoUrl: p.photoUrl,
              ),
            ),
        ],
      ],
    );
  }
}

/// 달 이동 · 오늘 버튼: 옅은 인디고 바탕의 둥근 버튼 (글자 또는 아이콘).
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    this.icon,
    this.label,
    this.tooltip,
    required this.onTap,
  });

  final IconData? icon;
  final String? label;
  final String? tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final ShapeBorder shape = label == null
        ? const CircleBorder()
        : const StadiumBorder();
    final child = Material(
      color: palette.brand.withValues(alpha: 0.1),
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: SizedBox(
          width: label == null ? 36 : null,
          height: 36,
          child: Center(
            widthFactor: label == null ? null : 1,
            child: label != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      label!,
                      style: TextStyle(color: palette.brand, fontSize: 13),
                    ),
                  )
                : Icon(icon, size: 18, color: palette.brand),
          ),
        ),
      ),
    );
    return tooltip == null ? child : Tooltip(message: tooltip!, child: child);
  }
}

/// 달력 아래 범례 한 칸: 모임은 짧은 막대, 생일은 점.
class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, this.bar = false});

  final Color color;
  final String label;
  final bool bar;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: bar ? 14 : 7,
        height: bar ? 4 : 7,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(color: context.palette.muted, fontSize: 12)),
    ],
  );
}

/// 모임 줄 앞의 둥근 아이콘 칸 (생일 줄의 사진과 같은 크기).
class _Badge extends StatelessWidget {
  const _Badge({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      shape: BoxShape.circle,
    ),
    child: Icon(icon, size: 20, color: color),
  );
}

/// 그날의 모임 · 생일 한 줄: 둥근 카드 하나(앞에 아이콘 또는 사진, 오른쪽 끝에 종류 알약). 모임은 누르면 상세 화면이 열린다.
class _Bubble extends StatelessWidget {
  /// 카드 안쪽 높이(아이콘 · 사진 칸 기준). 일정 없음 카드와 같다.
  static const contentHeight = 44.0;

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
    final radius = BorderRadius.circular(AppRadius.card);
    final gutter = textGutter(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, 6, gutter, 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: AppShadow.soft(context),
        ),
        child: Material(
          color: palette.surface,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: palette.border),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: _Bubble.contentHeight,
                ),
                child: Row(
                  children: [
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: 14),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 15),
                          ),
                          if (sub.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                sub,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: palette.muted,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // 종류(모임 · 생일) 알약.
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(color: color, fontSize: 12),
                      ),
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

/// 일정이 없는 날: 일정 카드와 같은 크기 · 같은 모양의 카드에 "일정 없음".
class _EmptyDay extends StatelessWidget {
  const _EmptyDay();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final radius = BorderRadius.circular(AppRadius.card);
    final gutter = textGutter(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, 6, gutter, 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: AppShadow.soft(context),
        ),
        child: Material(
          color: palette.surface,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: palette.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: _Bubble.contentHeight,
              ),
              child: Center(
                child: Text(
                  '일정 없음',
                  style: TextStyle(color: palette.muted, fontSize: 14),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
