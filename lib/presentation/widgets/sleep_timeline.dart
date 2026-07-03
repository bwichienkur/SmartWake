import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/sleep_session.dart';
import '../../domain/entities/sleep_stage.dart';

class SleepTimeline extends StatelessWidget {
  const SleepTimeline({super.key, required this.segments});

  final List<SleepSegment> segments;

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) return const SizedBox.shrink();

    final start = segments.first.startTime;
    final end = segments.last.endTime;
    final totalMinutes = end.difference(start).inMinutes;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 48,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: segments.map((segment) {
                      final width = segment.duration.inMinutes / totalMinutes;
                      return Expanded(
                        flex: (width * 1000).round().clamp(1, 1000),
                        child: GestureDetector(
                          onTap: () => _showSegmentDetails(context, segment),
                          child: Container(
                            color: _stageColor(segment.stage),
                            child: Tooltip(
                              message:
                                  '${segment.stage.displayName}\n'
                                  '${_formatTime(segment.startTime)} - '
                                  '${_formatTime(segment.endTime)}',
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: SleepStage.values
                    .where((s) => s != SleepStage.unknown)
                    .map((stage) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _stageColor(stage),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              stage.displayName,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSegmentDetails(BuildContext context, SleepSegment segment) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              segment.stage.displayName,
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '${_formatTime(segment.startTime)} – ${_formatTime(segment.endTime)} '
              '(${segment.duration.inMinutes} min)',
            ),
            if (segment.heartRate != null) ...[
              const SizedBox(height: 12),
              Text('Heart rate: ${segment.heartRate!.toStringAsFixed(0)} bpm'),
            ],
            if (segment.movementScore != null) ...[
              const SizedBox(height: 8),
              Text('Movement: ${(segment.movementScore! * 100).toStringAsFixed(0)}%'),
            ],
            if (segment.hrv != null) ...[
              const SizedBox(height: 8),
              Text('HRV: ${segment.hrv!.toStringAsFixed(1)} ms'),
            ],
          ],
        ),
      ),
    );
  }

  Color _stageColor(SleepStage stage) => switch (stage) {
        SleepStage.deep => AppColors.deepSleep,
        SleepStage.light => AppColors.lightSleep,
        SleepStage.rem => AppColors.remSleep,
        SleepStage.awake => AppColors.awake,
        SleepStage.unknown => Colors.grey,
      };

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
