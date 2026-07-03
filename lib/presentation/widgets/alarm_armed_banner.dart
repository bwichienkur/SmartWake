import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/alarm.dart';

class AlarmArmedBanner extends StatelessWidget {
  const AlarmArmedBanner({
    super.key,
    required this.status,
    this.nextAlarm,
  });

  final AlarmArmedStatus status;
  final Alarm? nextAlarm;

  @override
  Widget build(BuildContext context) {
    final (color, icon, text) = switch (status) {
      AlarmArmedStatus.armed => (
          AppColors.success,
          Icons.shield_moon,
          nextAlarm != null
              ? 'Alarm armed — next: ${_formatTime(nextAlarm!.latestWakeTime)}'
              : 'Alarm armed',
        ),
      AlarmArmedStatus.noAlarms => (
          AppColors.warning,
          Icons.alarm_off,
          'No alarms set',
        ),
      AlarmArmedStatus.disabled => (
          Colors.grey,
          Icons.alarm_off,
          'All alarms disabled',
        ),
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) {
    final h = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
    final m = t.minute.toString().padLeft(2, '0');
    final ampm = t.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }
}
