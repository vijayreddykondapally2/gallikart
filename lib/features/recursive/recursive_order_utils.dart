const _monthLabels = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

DateTime _stripTime(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime weekStart(DateTime date) {
  final normalized = _stripTime(date);
  final daysSinceSunday = normalized.weekday % 7; // Sunday -> 0
  return normalized.subtract(Duration(days: daysSinceSunday));
}

List<DateTime> generateUpcomingWeekStarts({int count = 6, DateTime? from}) {
  final start = weekStart(from ?? DateTime.now());
  return List.generate(count, (index) => start.add(Duration(days: index * 7)));
}

String formatWeekStartLabel(DateTime date) {
  final start = weekStart(date);
  final month = _monthLabels[start.month - 1];
  return 'Week of ${start.day} $month';
}

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
