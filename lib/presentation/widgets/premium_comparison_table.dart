import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class PremiumComparisonTable extends StatelessWidget {
  const PremiumComparisonTable({super.key});

  static const _rows = [
    ('Smart Wake window', '15 min', '90 min'),
    ('Sleep history', '7 days', 'Unlimited'),
    ('Wake-up challenges', '3 types', 'All 13 types'),
    ('AI sleep insights', '—', '✓'),
    ('Cloud backup', '—', '✓'),
    ('Nap Smart Wake', '—', '✓'),
    ('Travel mode', '—', '✓'),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Free vs Premium', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(flex: 2, child: SizedBox()),
                Expanded(child: Text('Free', style: Theme.of(context).textTheme.labelLarge)),
                Expanded(
                  child: Text(
                    'Premium',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                        ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ..._rows.map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(row.$1)),
                    Expanded(child: Text(row.$2, style: Theme.of(context).textTheme.bodySmall)),
                    Expanded(
                      child: Text(
                        row.$3,
                        style: TextStyle(
                          color: row.$3 == '—' ? Colors.grey : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Yearly plan: \$${(AppConstants.premiumYearlyPrice / 12).toStringAsFixed(2)}/mo',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
