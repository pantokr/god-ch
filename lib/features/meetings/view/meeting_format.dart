import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../data/models/meeting.dart';
import '../../home/view/content_widgets.dart';

/// 모임 썸네일의 가로:세로 비. 목록 카드에 실제로 게시되는 비율이고, 모임 만들기의 미리보기도 같은 비율이다.
const meetingThumbRatio = 1.3;

/// 모임 썸네일: 올린 이미지, 없으면 Storage의 임시 이미지, 그것도 없으면 빈 면.
class MeetingThumb extends StatelessWidget {
  const MeetingThumb(this.meeting, {super.key});

  final Meeting meeting;

  @override
  Widget build(BuildContext context) {
    if (meeting.imageUrl.isNotEmpty) return ContentImage(meeting.imageUrl);
    return FutureBuilder<String?>(
      future: AppScope.read(context).meetings.exampleUrl(meeting.id),
      builder: (context, snap) => ContentImage(snap.data),
    );
  }
}

/// 모임 날짜 글자: "11월 6일 금요일 19:30".
String meetingWhen(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.month}월 ${d.day}일 ${'월화수목금토일'[d.weekday - 1]}요일 '
      '${two(d.hour)}:${two(d.minute)}';
}

/// 카드의 날짜: "11/06".
String meetingDay(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.month)}/${two(d.day)}';
}

/// 남은 날 표시: "D-5", 오늘은 "D-0". 이미 지난 모임은 null (남은 자리 배지가 "종료"를 알린다).
String? meetingDDay(DateTime d, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final days = DateTime(
    d.year,
    d.month,
    d.day,
  ).difference(DateTime(today.year, today.month, today.day)).inDays;
  return days < 0 ? null : 'D-$days';
}

/// 카드에 쓰는 짧은 줄: "11/06 서대문". D-N은 남은 자리 배지 옆에 따로 보인다.
String meetingLine(DateTime d, String place) {
  final day = meetingDay(d);
  return place.isEmpty ? day : '$day $place';
}
