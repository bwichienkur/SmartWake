import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/sleep_confidence.dart';
import '../../../domain/entities/sleep_session.dart';
import '../../widgets/disclaimer_banner.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/sleep_comparison_card.dart';
import '../../widgets/sleep_insights_cards.dart';
import '../../widgets/sleep_score_ring.dart';
import '../../widgets/sleep_timeline.dart';

enum AnalyticsPeriod { daily, weekly, monthly, yearly }

class SleepDashboardScreen extends ConsumerStatefulWidget {
  const SleepDashboardScreen({super.key});

  @override
  ConsumerState<SleepDashboardScreen> createState() =>
      _SleepDashboardScreenState();
}

class _SleepDashboardScreenState extends ConsumerState<SleepDashboardScreen> {
  AnalyticsPeriod _period = AnalyticsPeriod.weekly;

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(sleepSessionsProvider);
    final userAsync = ref.watch(userProvider);
    final isPremium = userAsync.maybeWhen(
      data: (u) => u?.isPremium ?? false,
      orElse: () => false,
    );
    final estimate = ref.watch(sleepStageEstimatorProvider).lastEstimate;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            floating: true,
            pinned: true,
            title: const Text('Sleep'),
            actions: [
              if (!isPremium)
                TextButton(
                  onPressed: () => context.push('/premium'),
                  child: const Text('Upgrade'),
                ),
            ],
          ),
          const SliverToBoxAdapter(child: DisclaimerBanner()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<AnalyticsPeriod>(
                segments: AnalyticsPeriod.values
                    .map((p) => ButtonSegment(
                          value: p,
                          label: Text(p.name[0].toUpperCase() + p.name.substring(1)),
                        ))
                    .toList(),
                selected: {_period},
                onSelectionChanged: (s) {
                  if (s.first != AnalyticsPeriod.weekly && !isPremium) {
                    context.push('/premium');
                    return;
                  }
                  setState(() => _period = s.first);
                },
              ),
            ),
          ),
          sessionsAsync.when(
            data: (sessions) {
              final list = sessions as List<SleepSession>;
              if (list.isEmpty) {
                return SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.bedtime,
                    title: 'No sleep data yet',
                    subtitle: 'Your sleep will be tracked when Smart Wake alarms run',
                  ),
                );
              }
              final latest = list.first;
              final averages = ref.read(sleepAnalyticsProvider).compareAverages(list);
              final showWearableCta = estimate?.confidence == SleepConfidence.low;
              return SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 16),
                  if (!isPremium) ...[
                    const PremiumSmartWakeUpsell(),
                    const SizedBox(height: 12),
                  ],
                  if (showWearableCta) ...[
                    const WearableConnectCard(),
                    const SizedBox(height: 12),
                  ],
                  Center(
                    child: SleepScoreRing(score: latest.sleepScore ?? 75),
                  ).animate().scale(duration: 600.ms),
                  const SizedBox(height: 16),
                  if (latest.wakeQuality != null)
                    WakeQualityCard(
                      score: latest.wakeQuality!,
                      wasSmartWake: latest.wasSmartWake ?? false,
                    ),
                  if (latest.wakeQuality != null) const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SleepComparisonCard(
                      lastNightScore: latest.sleepScore ?? 0,
                      averageScore: averages.avgScore,
                      lastNightHours: latest.totalSleep.inMinutes / 60.0,
                      averageHours: averages.avgHours,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _MetricsGrid(session: latest),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Last Night',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SleepTimeline(segments: latest.segments),
                  const SizedBox(height: 24),
                  _WeeklyChart(sessions: list.take(7).toList()),
                  if (isPremium) ...[
                    const SizedBox(height: 24),
                    _InsightsSection(sessions: list),
                  ] else
                    _PremiumInsightsTeaser(
                      onTap: () => context.push('/premium'),
                    ),
                  const SizedBox(height: 100),
                ]),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.session});

  final SleepSession session;

  @override
  Widget build(BuildContext context) {
    final total = session.totalSleep;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.8,
        children: [
          _MetricCard(
            label: 'Duration',
            value: '${total.inHours}h ${total.inMinutes % 60}m',
            icon: Icons.schedule,
            color: AppColors.primary,
          ),
          _MetricCard(
            label: 'Efficiency',
            value: '${(session.sleepEfficiency ?? 85).round()}%',
            icon: Icons.speed,
            color: AppColors.success,
          ),
          _MetricCard(
            label: 'Deep Sleep',
            value: '${session.deepSleep.inMinutes}m',
            icon: Icons.nights_stay,
            color: AppColors.deepSleep,
          ),
          _MetricCard(
            label: 'REM',
            value: '${session.remSleep.inMinutes}m',
            icon: Icons.psychology,
            color: AppColors.remSleep,
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const Spacer(),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.sessions});

  final List<SleepSession> sessions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Weekly Overview', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 10,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            if (value.toInt() >= sessions.length) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              DateFormat.E().format(sessions[value.toInt()].bedTime),
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: sessions.asMap().entries.map((e) {
                      final hours = e.value.totalSleep.inMinutes / 60.0;
                      return BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: hours,
                            color: AppColors.primary,
                            width: 16,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightsSection extends ConsumerWidget {
  const _InsightsSection({required this.sessions});

  final List<SleepSession> sessions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(sleepRepositoryProvider).generateInsights(),
      builder: (context, snapshot) {
        final insights = snapshot.data ?? [];
        if (insights.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sleep Insights', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ...insights.map(
                (i) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.lightbulb, color: AppColors.accent),
                    title: Text(i.title),
                    subtitle: Text(i.description),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PremiumInsightsTeaser extends StatelessWidget {
  const _PremiumInsightsTeaser({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.premium),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unlock Sleep Insights',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Personalized tips from your sleep patterns',
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
