String _two(int n) => n.toString().padLeft(2, '0');

/// 화면에 보여줄 날짜: 올해면 MM.DD (예: 11.09), 작년과 그 이전이면 YY.MM.DD (예: 25.11.09). 값이 없으면 빈 문자열.
String fmtDate(DateTime? d) {
  if (d == null) return '';
  final md = '${_two(d.month)}.${_two(d.day)}';
  return d.year == DateTime.now().year ? md : '${_two(d.year % 100)}.$md';
}

/// 글 · 댓글의 작성 일시: 올해면 MM.DD HH:mm (예: 11.09 14:05), 작년과 그 이전이면 YY.MM.DD HH:mm (예: 25.11.09 14:05).
/// 값이 없으면 빈 문자열.
String fmtDateTime(DateTime? d) {
  if (d == null) return '';
  return '${fmtDate(d)} ${_two(d.hour)}:${_two(d.minute)}';
}

/// 글 · 댓글 같은 작성 시각의 표기 방식 (개인 설정의 "일시 표기").
enum DateStyle {
  /// 몇 초 전 · 몇 분 전 · 몇 시간 전 · 몇 일 전 · 몇 주 전.
  relative('상대'),

  /// 날짜와 시각 (예: 11.09 14:05).
  absolute('날짜');

  const DateStyle(this.label);

  final String label;
}

/// 지금 고른 일시 표기. 개인 설정이 바뀔 때마다 `PreferencesController`가 맞춰 둔다
/// (앱 전체가 다시 그려지므로 [fmtPosted]를 쓰는 곳이 모두 따라 바뀐다).
DateStyle dateStyle = DateStyle.relative;

/// 지난 시간을 짧게 말한다: 몇 초 전 · 몇 분 전 · 몇 시간 전 · 1~6일 전 · 1~3주 전.
/// 4주(28일)가 지나면 날짜로 보인다 (올해면 MM.DD, 작년 이전이면 YY.MM.DD). [now]는 시험용이다.
/// 시각이 지금보다 앞서 있어도(서버 시각이 아직 확정되기 전 · 기기 시계 차이) "방금 전"이다.
String fmtAgo(DateTime d, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(d);
  if (diff.inSeconds < 1) return '방금 전';
  if (diff.inSeconds < 60) return '${diff.inSeconds}초 전';
  if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
  if (diff.inHours < 24) return '${diff.inHours}시간 전';
  if (diff.inDays < 7) return '${diff.inDays}일 전';
  if (diff.inDays < 28) return '${diff.inDays ~/ 7}주 전';
  return fmtDate(d);
}

/// 글 · 댓글 · 알림처럼 "언제 올렸는지"를 보이는 곳의 표기: 개인 설정의 [dateStyle]을 따른다
/// (상대면 [fmtAgo], 날짜면 [fmtDateTime]). 값이 없으면 빈 문자열.
/// 가입일 · 활동 기록처럼 정확한 시각이 필요한 기록은 [fmtDateTime]을 그대로 쓴다.
String fmtPosted(DateTime? d, {DateTime? now}) {
  if (d == null) return '';
  return dateStyle == DateStyle.relative ? fmtAgo(d, now: now) : fmtDateTime(d);
}

/// 글에 정해 둔 날짜([date])에 작성 시각([at])의 시간을 붙인다 (예: 묵상 날짜 11.09 + 작성 14:05).
/// 작성 시각을 모르면 날짜만 보인다.
String fmtDateAt(DateTime date, DateTime? at) {
  if (at == null) return fmtDate(date);
  return '${fmtDate(date)} ${_two(at.hour)}:${_two(at.minute)}';
}

/// 이메일을 목록에 맞게 줄인다: 앞부분이 [keep]자보다 길면 잘라 "…"를 붙이고 도메인은 그대로 둔다.
/// 예: pantokrator3841@gmail.com → pantokra…@gmail.com
String shortEmail(String email, {int keep = 8}) {
  final at = email.indexOf('@');
  if (at <= keep) return email;
  return '${email.substring(0, keep)}…${email.substring(at)}';
}
