/// intl 패키지 없이 쓰는 간단한 날짜 포맷터.
String formatDate(DateTime? date) {
  if (date == null) return '-';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${date.year}.${two(date.month)}.${two(date.day)}';
}

/// 'MM.dd' 형태의 짧은 날짜.
String formatShortDate(DateTime? date) {
  if (date == null) return '-';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(date.month)}.${two(date.day)}';
}

const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

/// '2026.10.02 (금)' 형태.
String formatDateWithWeekday(DateTime date) =>
    '${formatDate(date)} (${_weekdays[date.weekday - 1]})';

/// 시·분·초를 버린 날짜.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// 오늘 날짜(시각 없음).
DateTime today() => dateOnly(DateTime.now());

/// DB 저장용 'yyyy-MM-dd' 문자열. 문자열 정렬 = 날짜 정렬.
String toDbDate(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)}';
}

/// 같은 날짜인지 (시각 무시).
bool isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
