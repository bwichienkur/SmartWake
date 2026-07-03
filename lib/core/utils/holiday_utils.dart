import '../../domain/entities/alarm.dart';

String dateKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// US federal holidays (fixed + observed dates).
const usFederalHolidays = {
  '2026-01-01',
  '2026-01-19',
  '2026-02-16',
  '2026-05-25',
  '2026-06-19',
  '2026-07-03',
  '2026-09-07',
  '2026-10-12',
  '2026-11-11',
  '2026-11-26',
  '2026-12-25',
  '2027-01-01',
};

bool isHolidayToday() => usFederalHolidays.contains(dateKey(DateTime.now()));

bool shouldSkipAlarmToday(Alarm alarm) {
  if (alarm.skipToday) return true;
  if (alarm.skipHolidays && isHolidayToday()) return true;
  return false;
}
