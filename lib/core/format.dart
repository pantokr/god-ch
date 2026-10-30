/// 화면에 보여줄 날짜 (예: 2026.10.21). 값이 없으면 빈 문자열.
String fmtDate(DateTime? d) {
  if (d == null) return '';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}.${two(d.month)}.${two(d.day)}';
}

/// 글 · 댓글의 작성 일시 (예: 2026.10.21 14:05). 값이 없으면 빈 문자열.
String fmtDateTime(DateTime? d) {
  if (d == null) return '';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${fmtDate(d)} ${two(d.hour)}:${two(d.minute)}';
}

/// 글에 정해 둔 날짜([date])에 작성 시각([at])의 시간을 붙인다 (예: 묵상 날짜 2026.10.21 + 작성 14:05).
/// 작성 시각을 모르면 날짜만 보인다.
String fmtDateAt(DateTime date, DateTime? at) {
  if (at == null) return fmtDate(date);
  String two(int n) => n.toString().padLeft(2, '0');
  return '${fmtDate(date)} ${two(at.hour)}:${two(at.minute)}';
}

/// 이메일을 목록에 맞게 줄인다: 앞부분이 [keep]자보다 길면 잘라 "…"를 붙이고 도메인은 그대로 둔다.
/// 예: pantokrator3841@gmail.com → pantokra…@gmail.com
String shortEmail(String email, {int keep = 8}) {
  final at = email.indexOf('@');
  if (at <= keep) return email;
  return '${email.substring(0, keep)}…${email.substring(at)}';
}
