import '../../domain/entities/user_profile.dart';
import '../alarm/notification_service.dart';

/// Schedules nightly bedtime and wind-down reminder notifications.
class BedtimeReminderService {
  BedtimeReminderService(this._notifications);

  static const bedtimeNotificationId = 88001;
  static const windDownNotificationId = 88002;

  final NotificationService _notifications;

  Future<void> syncFromPreferences(UserPreferences prefs) async {
    await _notifications.cancelNotification(bedtimeNotificationId);
    await _notifications.cancelNotification(windDownNotificationId);

    if (!prefs.notificationsEnabled) return;

    if (prefs.bedtimeReminderEnabled) {
      await _scheduleDaily(
        id: bedtimeNotificationId,
        title: 'Time for bed',
        body: 'Wind down now for a better Smart Wake tomorrow.',
        hour: prefs.typicalBedtimeHour,
        minute: prefs.typicalBedtimeMinute,
      );
    }

    if (prefs.windDownEnabled) {
      final windDown = _subtractMinutes(
        prefs.typicalBedtimeHour,
        prefs.typicalBedtimeMinute,
        30,
      );
      await _scheduleDaily(
        id: windDownNotificationId,
        title: 'Wind-down mode',
        body: 'Dim the lights and relax — bedtime in 30 minutes.',
        hour: windDown.$1,
        minute: windDown.$2,
      );
    }
  }

  Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    var next = DateTime.now();
    next = DateTime(next.year, next.month, next.day, hour, minute);
    if (next.isBefore(DateTime.now())) {
      next = next.add(const Duration(days: 1));
    }
    await _notifications.scheduleAlarmNotification(
      id: id,
      title: title,
      body: body,
      scheduledTime: next,
    );
  }

  (int, int) _subtractMinutes(int hour, int minute, int subtract) {
    final total = hour * 60 + minute - subtract;
    final normalized = (total + 24 * 60) % (24 * 60);
    return (normalized ~/ 60, normalized % 60);
  }
}
