import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/theme/app_theme.dart';

class AlarmReadinessCard extends ConsumerWidget {
  const AlarmReadinessCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(alarmReadinessProvider);

    return reportAsync.when(
      data: (report) {
        final actionable = report.issues.where((i) => i.canFixInApp).toList();
        final warnings = report.issues.where((i) => !i.canFixInApp).toList();
        if (actionable.isEmpty && warnings.isEmpty) {
          return const SizedBox.shrink();
        }

        final color = report.isReady ? AppColors.warning : AppColors.error;
        final displayIssues = [...actionable, ...warnings];

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    report.isReady ? Icons.info_outline : Icons.warning_amber,
                    color: color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      report.isReady
                          ? 'Improve alarm reliability'
                          : 'Alarms may not ring reliably',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...displayIssues.map(
                (issue) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              issue.title,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              issue.description,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (issue.canFixInApp)
                        TextButton(
                          onPressed: () async {
                            await ref
                                .read(alarmReadinessServiceProvider)
                                .fixIssue(issue.id);
                            ref.invalidate(alarmReadinessProvider);
                          },
                          child: const Text('Fix'),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
