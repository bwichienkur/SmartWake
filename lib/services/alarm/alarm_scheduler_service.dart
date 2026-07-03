import 'package:timezone/data/latest.dart' as tz;

import '../../domain/entities/alarm.dart';
import '../../core/utils/holiday_utils.dart';
import 'notification_service.dart';

/// Schedules native local notifications for reliable alarm delivery.
class AlarmSchedulerService {
  AlarmSchedulerService(this._notifications);

  final NotificationService _notifications;

  int _notificationIdFor(String alarmId, DateTime when) =>
      alarmId.hashCode ^ when.millisecondsSinceEpoch.hashCode;

  Future<void> scheduleAlarm(Alarm alarm) async {
    if (!alarm.isEnabled) {
      await cancelAlarm(alarm.id);
      return;
    }

    if (shouldSkipAlarmToday(alarm)) return;

    final windowStart = _nextOccurrence(alarm.earliestWakeTime);
    final windowEnd = _nextOccurrence(alarm.latestWakeTime);

    await _notifications.scheduleAlarmNotification(
      id: _notificationIdFor(alarm.id, windowStart),
      title: 'SmartWake — ${alarm.label}',
      body: 'Smart Wake window opening. Light sleep detection active.',
      scheduledTime: windowStart,
    );

    await _notifications.scheduleAlarmNotification(
      id: _notificationIdFor(alarm.id, windowEnd),
      title: 'SmartWake — ${alarm.label}',
      body: 'Time to wake up!',
      scheduledTime: windowEnd,
    );
  }

  Future<void> scheduleTestAlarm({
    Duration delay = const Duration(minutes: 1),
  }) async {
    await _notifications.scheduleAlarmNotification(
      id: 99999,
      title: 'SmartWake Test Alarm',
      body: 'If you see this, notifications are working!',
      scheduledTime: DateTime.now().add(delay),
    );
  }

  Future<void> cancelAlarm(String alarmId) async {
    for (var i = 0; i < 14; i++) {
      await _notifications.cancelNotification(alarmId.hashCode ^ i);
    }
  }

  Future<void> rescheduleAll(List<Alarm> alarms) async {
    await _notifications.cancelAll();
    for (final alarm in alarms.where((a) => a.isEnabled)) {
      await scheduleAlarm(alarm);
    }
  }

  DateTime _nextOccurrence(DateTime time) {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (next.isBefore(now)) next = next.add(const Duration(days: 1));
    return next;
  }
}

Future<void> initializeTimezones() async {
  tz.initializeTimeZones();
}
