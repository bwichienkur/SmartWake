import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/di/providers.dart';
import '../../../domain/entities/sleep_session.dart';
import '../../widgets/sleep_timeline.dart';

class SleepDetailScreen extends ConsumerWidget {
  const SleepDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sleep Detail')),
      body: FutureBuilder<SleepSession?>(
        future: ref.read(sleepRepositoryProvider).getSessionById(sessionId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final session = snapshot.data;
          if (session == null) {
            return const Center(child: Text('Session not found'));
          }

          final dateFormat = DateFormat.yMMMEd();
          final timeFormat = DateFormat.jm();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                dateFormat.format(session.bedTime),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '${timeFormat.format(session.bedTime)} – '
                '${timeFormat.format(session.wakeTime)}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              _DetailRow('Sleep Score', '${session.sleepScore ?? '—'}'),
              _DetailRow(
                'Duration',
                '${session.totalSleep.inHours}h '
                '${session.totalSleep.inMinutes % 60}m',
              ),
              _DetailRow(
                'Efficiency',
                '${(session.sleepEfficiency ?? 0).round()}%',
              ),
              _DetailRow('Deep', '${session.deepSleep.inMinutes} min'),
              _DetailRow('Light', '${session.lightSleep.inMinutes} min'),
              _DetailRow('REM', '${session.remSleep.inMinutes} min'),
              _DetailRow('Awake', '${session.awakeTime.inMinutes} min'),
              if (session.wasSmartWake == true)
                _DetailRow('Wake Type', 'Smart Wake'),
              const SizedBox(height: 24),
              Text('Timeline', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              SleepTimeline(segments: session.segments),
              if (session.insights.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Insights', style: Theme.of(context).textTheme.titleLarge),
                ...session.insights.map(
                  (i) => ListTile(
                    leading: const Icon(Icons.lightbulb_outline),
                    title: Text(i),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
