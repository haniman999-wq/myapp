/// intl 패키지 없이 쓰는 간단한 날짜 포맷터.
String formatDate(DateTime? date) {
  if (date == null) return '-';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${date.year}.${two(date.month)}.${two(date.day)}';
}
