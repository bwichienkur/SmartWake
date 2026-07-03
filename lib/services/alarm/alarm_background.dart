import 'dart:io';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/widgets.dart';

import '../../core/utils/holiday_utils.dart';
import '../../data/datasources/local/alarm_local_datasource.dart';
import '../../data/datasources/local/local_storage_service.dart';
import 'alarm_scheduler_service.dart';
import 'notification_service.dart';

const alarmReschedulePeriodicId = 424242;
const alarmBootRescheduleId = 424243;

/// Initializes Android background alarm rescheduling (boot + periodic safety net).
Future<void> initAndroidAlarmBackground() async {
  if (!Platform.isAndroid) return;

  await AndroidAlarmManager.initialize();

  await AndroidAlarmManager.periodic(
    const Duration(hours: 6),
    alarmReschedulePeriodicId,
    rescheduleAlarmsCallback,
    exact: true,
    wakeup: true,
    rescheduleOnReboot: true,
  );

  await AndroidAlarmManager.oneShot(
    const Duration(seconds: 5),
    alarmBootRescheduleId,
    rescheduleAlarmsCallback,
    exact: true,
    wakeup: true,
    rescheduleOnReboot: true,
  );
}

@pragma('vm:entry-point')
Future<void> rescheduleAlarmsCallback() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final storage = LocalStorageService();
    await storage.init();

    final alarms = await AlarmLocalDataSource(storage).getAlarms();
    final enabled =
        alarms.where((a) => a.isEnabled && !shouldSkipAlarmToday(a)).toList();

    final notifications = NotificationService();
    await notifications.init();

    final scheduler = AlarmSchedulerService(notifications);
    await scheduler.rescheduleAll(enabled);
  } catch (e) {
    debugPrint('Alarm reschedule failed: $e');
  }
}
