/// 화면에 보여줄 날짜 (예: 2026.10.21). 값이 없으면 빈 문자열.
String fmtDate(DateTime? d) {
  if (d == null) return '';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}.${two(d.month)}.${two(d.day)}';
}
