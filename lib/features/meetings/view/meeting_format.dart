/// 모임 날짜 글자: "11월 6일 금요일 19:30".
String meetingWhen(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.month}월 ${d.day}일 ${'월화수목금토일'[d.weekday - 1]}요일 '
      '${two(d.hour)}:${two(d.minute)}';
}

/// 카드에 쓰는 짧은 줄: "11월 6일 · 서대문".
String meetingLine(DateTime d, String place) {
  final day = '${d.month}월 ${d.day}일 ${'월화수목금토일'[d.weekday - 1]}요일';
  return place.isEmpty ? day : '$day · $place';
}
