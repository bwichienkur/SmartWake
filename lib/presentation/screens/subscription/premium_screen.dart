import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/premium_comparison_table.dart';

class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  static const _features = [
    ('Smart Wake up to 90 min', Icons.auto_awesome),
    ('Unlimited sleep history', Icons.history),
    ('AI sleep insights', Icons.psychology),
    ('All wake-up challenges', Icons.videogame_asset),
    ('Cloud backup & sync', Icons.cloud),
    ('Premium alarm sounds', Icons.music_note),
    ('Nap Smart Wake', Icons.nightlight),
    ('Relaxation audio', Icons.spa),
    ('Travel time-zone optimization', Icons.flight),
    ('Calendar-aware alarms', Icons.calendar_month),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('SmartWake Premium'),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.premium, AppColors.accent, AppColors.primary],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.star, size: 64, color: Colors.white),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  '${AppConstants.trialDays}-day free trial, then choose your plan',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ..._features.asMap().entries.map((e) {
                  return ListTile(
                    leading: Icon(e.value.$2, color: AppColors.primary),
                    title: Text(e.value.$1),
                  )
                      .animate()
                      .fadeIn(delay: (e.key * 50).ms)
                      .slideX(begin: 0.05, end: 0);
                }),
                const SizedBox(height: 24),
                const PremiumComparisonTable(),
                const SizedBox(height: 24),
                _PlanCard(
                  title: 'Lifetime',
                  price: '\$${AppConstants.premiumLifetimePrice} once',
                  subtitle: 'Pay once, keep forever',
                  onTap: () {
                    ref.read(analyticsProvider).premiumViewed(source: 'lifetime');
                    ref.read(subscriptionServiceProvider).purchaseLifetime();
                  },
                ),
                const SizedBox(height: 12),
                _PlanCard(
                  title: 'Yearly',
                  price: '\$${AppConstants.premiumYearlyPrice}/year',
                  subtitle: '\$3.33/mo • Save 33% • Most popular',
                  highlighted: true,
                  onTap: () =>
                      ref.read(subscriptionServiceProvider).purchaseYearly(),
                ),
                const SizedBox(height: 12),
                _PlanCard(
                  title: 'Monthly',
                  price: '\$${AppConstants.premiumMonthlyPrice}/month',
                  subtitle: 'Cancel anytime',
                  onTap: () =>
                      ref.read(subscriptionServiceProvider).purchaseMonthly(),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () =>
                      ref.read(subscriptionServiceProvider).restorePurchases(),
                  child: const Text('Restore Purchases'),
                ),
                const SizedBox(height: 16),
                Text(
                  'Subscription automatically renews unless cancelled at least '
                  '24 hours before the end of the current period.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.subtitle,
    required this.onTap,
    this.highlighted = false,
  });

  final String title;
  final String price;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: highlighted ? AppColors.primary.withValues(alpha: 0.15) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: highlighted
            ? const BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
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
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Text(price, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
