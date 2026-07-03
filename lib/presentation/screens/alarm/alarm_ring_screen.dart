import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/alarm.dart';
import '../challenges/challenge_host.dart';

class AlarmRingScreen extends ConsumerWidget {
  const AlarmRingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.watch(alarmEngineProvider);
    final alarm = engine.activeAlarm;

    if (alarm == null) {
      return const Scaffold(body: Center(child: Text('No active alarm')));
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.4),
              AppColors.darkBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                Text(
                  alarm.label,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                _buildContent(context, ref, engine),
                const Spacer(flex: 2),
                if (engine.ringState == AlarmRingState.ringing ||
                    engine.ringState == AlarmRingState.countdown)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (alarm.snoozeEnabled)
                        TextButton.icon(
                          onPressed: () => engine.snooze(),
                          icon: const Icon(Icons.snooze),
                          label: Text('Snooze ${alarm.snoozeMinutes}m'),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, dynamic engine) {
    switch (engine.ringState as AlarmRingState) {
      case AlarmRingState.ringing:
        return Column(
          children: [
            const Icon(Icons.alarm, size: 80, color: AppColors.accent),
            const SizedBox(height: 16),
            Text(
              'Wake up!',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 40,
                  ),
            ),
          ],
        );
      case AlarmRingState.countdown:
        return Column(
          children: [
            Text(
              '${engine.countdownSeconds}',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 72,
                    color: AppColors.accent,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start your challenge before time runs out',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => engine.startChallenge(),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Challenge'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        );
      case AlarmRingState.challengeActive:
        return Expanded(
          child: Column(
            children: [
              if (engine.totalChallenges > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Challenge ${engine.currentChallengeNumber} of ${engine.totalChallenges}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              Expanded(
                child: ChallengeHost(
                  challengeType: engine.currentChallenge!,
                  alarm: engine.activeAlarm!,
                  onComplete: () => engine.completeChallenge(),
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
