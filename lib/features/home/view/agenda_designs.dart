import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../data/models/church_content.dart';
import 'block_theme.dart';
import 'content_widgets.dart';
import 'month_calendar.dart';

/// 일정표의 색 있는 디자인들. 색뿐 아니라 배치도 다르다.
/// - agenda_neon: 어두운 바탕에 세로 타임라인 (왼쪽 날짜 · 빛나는 점 · 오른쪽 카드).
/// - agenda_pastel: 파스텔 티켓 카드를 두 줄로 (왼쪽 큰 날짜 조각 · 점선 · 오른쪽 내용).
/// 기본 일정표(agenda)는 [EventTile] 목록이라 여기서 그리지 않는다.
class AgendaDesign extends StatelessWidget {
  const AgendaDesign({
    super.key,
    required this.variant,
    required this.items,
    required this.onOpen,
    required this.theme,
  });

  /// 'agenda_neon'(타임라인) 또는 'agenda_pastel'(티켓). 색은 [theme]이 정한다.
  final String variant;
  final BlockTheme theme;
  final List<ChurchContent> items;
  final void Function(ChurchContent) onOpen;

  List<ChurchContent> get _sorted =>
      [...items]..sort((a, b) => a.date.compareTo(b.date));

  @override
  Widget build(BuildContext context) => variant == 'agenda_pastel'
      ? _Tickets(
          items: _sorted,
          onOpen: onOpen,
          style: CalendarStyle.fromTheme(theme),
        )
      : _Timeline(
          items: _sorted,
          onOpen: onOpen,
          style: CalendarStyle.fromTheme(theme),
        );
}

/// 네온 타임라인.
class _Timeline extends StatelessWidget {
  const _Timeline({
    required this.items,
    required this.onOpen,
    required this.style,
  });

  final CalendarStyle style;
  final List<ChurchContent> items;
  final void Function(ChurchContent) onOpen;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.card + 2);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      decoration: BoxDecoration(
        gradient: style.body,
        borderRadius: radius,
        boxShadow: AppDepth.raised(context),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            _TimelineRow(
              style: style,
              event: items[i],
              last: i == items.length - 1,
              onTap: () => onOpen(items[i]),
            ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.style,
    required this.event,
    required this.last,
    required this.onTap,
  });

  final CalendarStyle style;
  final ChurchContent event;
  final bool last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = event.date;
    final summary = event.body.split('\n').first;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${d.day}',
                  style: TextStyle(
                    color: style.eventText,
                    fontSize: 24,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${weekdayLabel(d)}요일',
                  style: TextStyle(color: style.weekday, fontSize: 11.5),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 28,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // 점에서 아래 점까지 이어지는 빛나는 선.
                if (!last)
                  Positioned(
                    top: 14,
                    bottom: -2,
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(gradient: style.bubbleBar),
                    ),
                  ),
                Positioned(
                  top: 6,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: style.selected,
                      boxShadow: [
                        BoxShadow(
                          color: style.glow.withValues(alpha: 0.7),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: style.bubble,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(
                      color: style.glow.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            summary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: style.bubbleSub,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 파스텔 티켓.
class _Tickets extends StatelessWidget {
  const _Tickets({
    required this.items,
    required this.onOpen,
    required this.style,
  });

  final CalendarStyle style;
  final List<ChurchContent> items;
  final void Function(ChurchContent) onOpen;

  @override
  Widget build(BuildContext context) {
    return ColumnWrap(
      wide: 2,
      children: [
        for (final e in items)
          _Ticket(style: style, event: e, onTap: () => onOpen(e)),
      ],
    );
  }
}

class _Ticket extends StatelessWidget {
  const _Ticket({
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
    final radius = BorderRadius.circular(AppRadius.card + 4);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: AppDepth.raised(context, tint: style.glow),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(gradient: style.body),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 왼쪽 날짜 조각: 파스텔 그라데이션 위에 큰 날짜.
                    Container(
                      width: 70,
                      decoration: BoxDecoration(gradient: style.selected),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${d.month}월',
                            style: TextStyle(
                              color: style.selectedText.withValues(alpha: 0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${d.day}',
                            style: TextStyle(
                              color: style.selectedText,
                              fontSize: 28,
                              height: 1.05,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${weekdayLabel(d)}요일',
                            style: TextStyle(
                              color: style.selectedText.withValues(alpha: 0.85),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 티켓을 뜯는 점선.
                    SizedBox(
                      width: 14,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (var i = 0; i < 6; i++)
                            Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: style.weekday.withValues(alpha: 0.7),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(4, 12, 14, 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  summary,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: style.bubbleSub,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                          ],
                        ),
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
