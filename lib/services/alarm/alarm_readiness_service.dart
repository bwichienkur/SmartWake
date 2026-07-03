import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

import '../../domain/entities/alarm_readiness.dart';

/// Checks permissions and settings that affect alarm reliability.
class AlarmReadinessService {
  Future<AlarmReadinessReport> check() async {
    final issues = <AlarmReadinessIssue>[];

    final notificationStatus = await Permission.notification.status;
    if (!notificationStatus.isGranted) {
      issues.add(
        AlarmReadinessIssue(
          id: 'notifications',
          title: 'Notifications disabled',
          description: 'SmartWake needs notifications to ring alarms reliably.',
          severity: ReadinessSeverity.critical,
          canFixInApp: true,
        ),
      );
    }

    if (Platform.isAndroid) {
      final exactAlarm = await Permission.scheduleExactAlarm.status;
      if (!exactAlarm.isGranted) {
        issues.add(
          AlarmReadinessIssue(
            id: 'exact_alarm',
            title: 'Exact alarms not allowed',
            description:
                'Allow exact alarms so SmartWake can ring at the right time.',
            severity: ReadinessSeverity.critical,
            canFixInApp: true,
          ),
        );
      }

      issues.add(
        const AlarmReadinessIssue(
          id: 'battery',
          title: 'Check battery optimization',
          description:
              'Set SmartWake to Unrestricted in system battery settings.',
          severity: ReadinessSeverity.warning,
          canFixInApp: false,
        ),
      );
    }

    if (Platform.isIOS) {
      issues.add(
        const AlarmReadinessIssue(
          id: 'focus',
          title: 'Focus & Do Not Disturb',
          description:
              'Allow time-sensitive notifications for SmartWake in Focus settings.',
          severity: ReadinessSeverity.warning,
          canFixInApp: false,
        ),
      );
    }

    return AlarmReadinessReport(issues: issues);
  }

  Future<bool> requestNotifications() async {
    final result = await Permission.notification.request();
    return result.isGranted;
  }

  Future<bool> requestExactAlarm() async {
    if (!Platform.isAndroid) return true;
    final result = await Permission.scheduleExactAlarm.request();
    return result.isGranted;
  }

  Future<bool> fixIssue(String issueId) async {
    switch (issueId) {
      case 'notifications':
        return requestNotifications();
      case 'exact_alarm':
        return requestExactAlarm();
      default:
        return false;
    }
  }
}
