const weekdayShort = ['Երկ', 'Երք', 'Չրք', 'Հնգ', 'Ուր', 'Շբթ', 'Կիր'];

const weekdayFull = [
  'երկուշաբթի',
  'երեքշաբթի',
  'չորեքշաբթի',
  'հինգշաբթի',
  'ուրբաթ',
  'շաբաթ',
  'կիրակի',
];

const _months = [
  'հունվար',
  'փետրվար',
  'մարտ',
  'ապրիլ',
  'մայիս',
  'հունիս',
  'հուլիս',
  'օգոստոս',
  'սեպտեմբեր',
  'հոկտեմբեր',
  'նոյեմբեր',
  'դեկտեմբեր',
];

String weekdayName(int weekday, {bool full = false}) {
  final names = full ? weekdayFull : weekdayShort;
  return names[weekday - 1];
}

String formatDay(DateTime date) {
  return '${date.day} ${_months[date.month - 1]}, ${weekdayFull[date.weekday - 1]}';
}

String formatMonth(DateTime date) => '${_months[date.month - 1]} ${date.year}';

String formatDayTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${formatDay(date)}, $hour:$minute';
}

String formatPercent(double? value) {
  if (value == null) return '—';
  return '${value.toStringAsFixed(1)}%';
}

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String dueLabel(DateTime due) {
  final today = dateOnly(DateTime.now());
  final day = dateOnly(due);
  final delta = day.difference(today).inDays;
  if (delta == 0) return 'Վերջնաժամկետն այսօր է';
  if (delta == 1) return 'Վերջնաժամկետը վաղն է';
  if (delta < 0) return 'Ուշացել է ${delta.abs()} օր';
  return 'Վերջնաժամկետ՝ ${formatDay(due)}';
}
