import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/alarm_presets.dart';
import '../../../core/di/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/alarm.dart';
import '../../widgets/alarm_armed_banner.dart';
import '../../widgets/alarm_card.dart';
import '../../widgets/confidence_badge.dart';
import '../../widgets/disclaimer_banner.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/smart_wake_explainer.dart';

class AlarmsScreen extends ConsumerStatefulWidget {
  const AlarmsScreen({super.key});

  @override
  ConsumerState<AlarmsScreen> createState() => _AlarmsScreenState();
}

class _AlarmsScreenState extends ConsumerState<AlarmsScreen> {
  static const _explainerKey = 'smart_wake_explainer_shown';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowExplainer());
  }

  Future<void> _maybeShowExplainer() async {
    final storage = ref.read(localStorageProvider);
    if (storage.get(_explainerKey) != null) return;
    await storage.put(_explainerKey, {'shown': true});
    if (mounted) await showSmartWakeExplainer(context);
  }

  @override
  Widget build(BuildContext context) {
    final alarmsAsync = ref.watch(alarmsProvider);
    final engine = ref.watch(alarmEngineProvider);
    final estimator = ref.watch(sleepStageEstimatorProvider);
    final calibration = ref.watch(calibrationStateProvider);
    final estimate = estimator.lastEstimate;
    final timeFormat = DateFormat.jm();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline),
                onPressed: () => showSmartWakeExplainer(context),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text('SmartWake', style: Theme.of(context).textTheme.titleLarge),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.3),
                      AppColors.darkBackground,
                    ],
                  ),
                ),
              ),
            ),
          ),
          alarmsAsync.when(
            data: (alarms) {
              final list = alarms as List<Alarm>;
              return SliverList(
                delegate: SliverChildListDelegate([
                  AlarmArmedBanner(
                    status: engine.getArmedStatus(list),
                    nextAlarm: engine.getNextAlarm(list),
                  ),
                  if (estimate != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ConfidenceBadge(
                        confidence: estimate.confidence,
                        source: estimate.source,
                        calibrationActive: calibration.isCalibrating,
                      ),
                    ),
                  if (calibration.isCalibrating)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Calibration: ${calibration.daysRemaining} days remaining. '
                        'Smart Wake improves as we learn your patterns.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  const DisclaimerBanner(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text('Quick presets', style: Theme.of(context).textTheme.titleMedium),
                  ),
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      children: AlarmPresets.all.map((preset) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ActionChip(
                            avatar: Icon(_presetIcon(preset.icon), size: 18),
                            label: Text(preset.label),
                            onPressed: () async {
                              final alarm = preset.toAlarm(id: const Uuid().v4());
                              await ref.read(alarmEngineProvider).scheduleAlarm(alarm);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (list.isEmpty)
                    EmptyState(
                      icon: Icons.alarm_add,
                      title: 'No alarms yet',
                      subtitle: 'Create your first Smart Wake alarm',
                      actionLabel: 'Add Alarm',
                      onAction: () => context.push('/alarm/new'),
                    )
                  else
                    ...list.asMap().entries.map((e) {
                      return AlarmCard(
                        alarm: e.value,
                        timeFormat: timeFormat,
                        onToggle: (enabled) async {
                          await ref.read(alarmEngineProvider).scheduleAlarm(
                                e.value.copyWith(isEnabled: enabled),
                              );
                        },
                        onTap: () => context.push('/alarm/${e.value.id}/edit'),
                        onSkipToday: () => ref.read(alarmEngineProvider).skipAlarmToday(e.value.id),
                      )
                          .animate()
                          .fadeIn(delay: (e.key * 80).ms)
                          .slideY(begin: 0.1, end: 0);
                    }),
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

  IconData _presetIcon(String name) => switch (name) {
        'work' => Icons.work_outline,
        'weekend' => Icons.weekend_outlined,
        'nap' => Icons.nightlight_outlined,
        'flight' => Icons.flight_outlined,
        _ => Icons.alarm,
      };
}
