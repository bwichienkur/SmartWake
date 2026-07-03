import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class SleepComparisonCard extends StatelessWidget {
  const SleepComparisonCard({
    super.key,
    required this.lastNightScore,
    required this.averageScore,
    required this.lastNightHours,
    required this.averageHours,
  });

  final int lastNightScore;
  final int averageScore;
  final double lastNightHours;
  final double averageHours;

  @override
  Widget build(BuildContext context) {
    final scoreDiff = lastNightScore - averageScore;
    final hoursDiff = lastNightHours - averageHours;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('vs Your Average', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _row(
              context,
              'Sleep score',
              '$lastNightScore',
              scoreDiff >= 0 ? '+$scoreDiff' : '$scoreDiff',
              scoreDiff >= 0 ? AppColors.success : AppColors.error,
            ),
            const SizedBox(height: 8),
            _row(
              context,
              'Duration',
              '${lastNightHours.toStringAsFixed(1)}h',
              hoursDiff >= 0
                  ? '+${hoursDiff.toStringAsFixed(1)}h'
                  : '${hoursDiff.toStringAsFixed(1)}h',
              hoursDiff >= 0 ? AppColors.success : AppColors.warning,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value,
    String diff,
    Color diffColor,
  ) {
    return Row(
      children: [
        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(width: 12),
        Text(diff, style: TextStyle(color: diffColor, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
