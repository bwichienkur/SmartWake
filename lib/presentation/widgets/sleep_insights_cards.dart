import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class WearableConnectCard extends StatelessWidget {
  const WearableConnectCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: AppColors.primary.withValues(alpha: 0.1),
        child: ListTile(
          leading: const Icon(Icons.watch, color: AppColors.primary),
          title: const Text('Connect a wearable'),
          subtitle: const Text(
            'Apple Watch or Health Connect improves Smart Wake accuracy.',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/settings'),
        ),
      ),
    );
  }
}

class PremiumSmartWakeUpsell extends StatelessWidget {
  const PremiumSmartWakeUpsell({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: InkWell(
          onTap: () => context.push('/premium'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.premium),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Extend Smart Wake to 90 minutes',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        'Free: ${AppConstants.freeMaxWakeWindowMinutes} min window · '
                        'Premium: ${AppConstants.premiumMaxWakeWindowMinutes} min',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WakeQualityCard extends StatelessWidget {
  const WakeQualityCard({
    super.key,
    required this.score,
    required this.wasSmartWake,
  });

  final double score;
  final bool wasSmartWake;

  @override
  Widget build(BuildContext context) {
    final label = score >= 80
        ? 'Great wake'
        : score >= 60
            ? 'Fair wake'
            : 'Groggy wake';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                score >= 80 ? Icons.wb_sunny : Icons.cloud,
                color: score >= 80 ? AppColors.accent : AppColors.lightSleep,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      'Wake quality: ${score.round()}/100'
                      '${wasSmartWake ? ' · Smart Wake' : ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
