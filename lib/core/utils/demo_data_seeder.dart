import 'package:uuid/uuid.dart';

import '../../domain/entities/sleep_session.dart';
import '../../domain/repositories/repositories.dart';
import '../../services/sleep/sleep_analytics_service.dart';
import '../../services/sleep/sleep_stage_estimator.dart';

/// Seeds demo sleep data for development and testing.
class DemoDataSeeder {
  DemoDataSeeder(
    this._sleepRepo,
    this._estimator,
    this._analytics,
  );

  final SleepRepository _sleepRepo;
  final SleepStageEstimator _estimator;
  final SleepAnalyticsService _analytics;
  static const _uuid = Uuid();

  Future<void> seedIfEmpty() async {
    final existing = await _sleepRepo.getSessions();
    if (existing.isNotEmpty) return;

    for (var i = 0; i < 7; i++) {
      final bedTime = DateTime.now().subtract(Duration(days: i + 1)).copyWith(
            hour: 23,
            minute: 30 - i * 5,
          );
      final wakeTime = bedTime.add(Duration(hours: 7, minutes: 30 + i * 10));

      final segments = _estimator.generateSessionSegments(
        bedTime: bedTime,
        wakeTime: wakeTime,
      );

      var session = SleepSession(
        id: _uuid.v4(),
        bedTime: bedTime,
        wakeTime: wakeTime,
        segments: segments,
        wasSmartWake: i.isEven,
      );

      session = SleepSession(
        id: session.id,
        bedTime: session.bedTime,
        wakeTime: session.wakeTime,
        segments: session.segments,
        sleepScore: _analytics.calculateSleepScore(session),
        sleepEfficiency: _analytics.calculateEfficiency(session),
        wakeQuality: 70.0 + i * 3,
        consistencyScore: _analytics.calculateConsistency([session]),
        wasSmartWake: session.wasSmartWake,
      );

      await _sleepRepo.saveSession(session);
    }
  }
}
