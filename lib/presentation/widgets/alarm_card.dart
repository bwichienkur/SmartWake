import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/alarm.dart';

class AlarmCard extends StatelessWidget {
  const AlarmCard({
    super.key,
    required this.alarm,
    required this.timeFormat,
    required this.onToggle,
    required this.onTap,
    this.onSkipToday,
  });

  final Alarm alarm;
  final DateFormat timeFormat;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;
  final VoidCallback? onSkipToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timeFormat.format(alarm.latestWakeTime),
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 36,
                          fontWeight: FontWeight.w300,
                          color: alarm.isEnabled
                              ? null
                              : theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alarm.label,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (alarm.isSmartWake)
                            _Chip(
                              icon: Icons.auto_awesome,
                              label:
                                  'Smart ${alarm.smartWakeWindowMinutes}min',
                              color: AppColors.primary,
                            ),
                          if (alarm.repeatDays.isNotEmpty)
                            _Chip(
                              icon: Icons.repeat,
                              label: _formatRepeatDays(alarm.repeatDays),
                            ),
                          if (alarm.skipToday)
                            _Chip(
                              icon: Icons.event_busy,
                              label: 'Skipped today',
                              color: AppColors.warning,
                            ),
                          _Chip(
                            icon: Icons.videogame_asset_outlined,
                            label: alarm.challenges.first.displayName,
                          ),
                        ],
                      ),
                      if (onSkipToday != null && alarm.isEnabled && !alarm.skipToday)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: onSkipToday,
                            child: const Text('Skip today'),
                          ),
                        ),
                    ],
                  ),
                ),
                Switch(
                  value: alarm.isEnabled,
                  onChanged: onToggle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatRepeatDays(List<int> days) {
    if (days.length == 7) return 'Every day';
    if (days.length == 5 &&
        {1, 2, 3, 4, 5}.every(days.contains)) {
      return 'Weekdays';
    }
    const names = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days.map((d) => names[d - 1]).join(' ');
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Colors.grey).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? Colors.grey),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color ?? Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
