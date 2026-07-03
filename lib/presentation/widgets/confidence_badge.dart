import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/sleep_confidence.dart';
import '../../domain/entities/sleep_stage.dart';

class ConfidenceBadge extends StatelessWidget {
  const ConfidenceBadge({
    super.key,
    required this.confidence,
    required this.source,
    this.calibrationActive = false,
  });

  final SleepConfidence confidence;
  final SensorSource source;
  final bool calibrationActive;

  @override
  Widget build(BuildContext context) {
    final color = switch (confidence) {
      SleepConfidence.high => AppColors.success,
      SleepConfidence.medium => AppColors.warning,
      SleepConfidence.low => AppColors.error,
    };

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        _chip(context, Icons.analytics_outlined, confidence.shortLabel, color),
        _chip(context, Icons.sensors, source.displayName, AppColors.primary),
        if (calibrationActive)
          _chip(context, Icons.tune, 'Calibrating', AppColors.accent),
      ],
    );
  }

  Widget _chip(BuildContext context, IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}

extension SensorSourceDisplay on SensorSource {
  String get displayName => switch (this) {
        SensorSource.appleWatch => 'Apple Watch',
        SensorSource.healthKit => 'HealthKit',
        SensorSource.healthConnect => 'Health Connect',
        SensorSource.wearOs => 'Wear OS',
        SensorSource.fitbit => 'Fitbit',
        SensorSource.garmin => 'Garmin',
        SensorSource.phoneAccelerometer => 'Phone sensors',
        SensorSource.phoneGyroscope => 'Phone sensors',
        SensorSource.phoneHeartRate => 'Phone HR',
        SensorSource.estimated => 'Estimated',
      };
}
