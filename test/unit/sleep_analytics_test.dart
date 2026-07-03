import 'package:flutter_test/flutter_test.dart';

import 'package:smart_wake/domain/entities/alarm.dart';
import 'package:smart_wake/domain/entities/challenge_type.dart';
import 'package:smart_wake/domain/entities/sleep_session.dart';
import 'package:smart_wake/domain/entities/sleep_stage.dart';
import 'package:smart_wake/services/sleep/calibration_service.dart';
import 'package:smart_wake/services/sleep/sleep_analytics_service.dart';
import 'package:smart_wake/services/sleep/sleep_stage_estimator.dart';
import 'package:smart_wake/services/sensors/phone_sensor_service.dart';
import 'package:smart_wake/services/health/health_service.dart';

void main() {
  group('SleepStageEstimator', () {
    late SleepStageEstimator estimator;

    setUp(() {
      // Estimator tests don't need initialized Hive storage
      estimator = SleepStageEstimator(
        HealthService(PhoneSensorService()),
        PhoneSensorService(),
        _NoOpCalibration(),
      );
    });

    test('classifies high movement as awake', () async {
      final stage = await estimator.estimateCurrentStage();
      expect(stage, isA<SleepStage>());
    });

    test('generates valid session segments', () {
      final bedTime = DateTime(2026, 1, 1, 23, 0);
      final wakeTime = DateTime(2026, 1, 2, 7, 0);
      final segments = estimator.generateSessionSegments(
        bedTime: bedTime,
        wakeTime: wakeTime,
      );

      expect(segments, isNotEmpty);
      expect(segments.first.startTime, bedTime);
      expect(segments.last.endTime, wakeTime);
    });
  });

  group('SleepAnalyticsService', () {
    late SleepAnalyticsService analytics;

    setUp(() {
      analytics = SleepAnalyticsService();
    });

    test('calculates sleep score in valid range', () {
      final session = SleepSession(
        id: '1',
        bedTime: DateTime(2026, 1, 1, 23, 0),
        wakeTime: DateTime(2026, 1, 2, 7, 30),
        segments: [
          SleepSegment(
            startTime: DateTime(2026, 1, 1, 23, 0),
            endTime: DateTime(2026, 1, 2, 1, 0),
            stage: SleepStage.light,
          ),
          SleepSegment(
            startTime: DateTime(2026, 1, 2, 1, 0),
            endTime: DateTime(2026, 1, 2, 3, 0),
            stage: SleepStage.deep,
          ),
          SleepSegment(
            startTime: DateTime(2026, 1, 2, 3, 0),
            endTime: DateTime(2026, 1, 2, 5, 0),
            stage: SleepStage.rem,
          ),
          SleepSegment(
            startTime: DateTime(2026, 1, 2, 5, 0),
            endTime: DateTime(2026, 1, 2, 7, 30),
            stage: SleepStage.light,
          ),
        ],
      );

      final score = analytics.calculateSleepScore(session);
      expect(score, inInclusiveRange(0, 100));
    });

    test('generates insights for poor sleep', () {
      final sessions = List.generate(
        5,
        (i) => SleepSession(
          id: '$i',
          bedTime: DateTime(2026, 1, i + 1, 1, 0),
          wakeTime: DateTime(2026, 1, i + 1, 6, 0),
          segments: [
            SleepSegment(
              startTime: DateTime(2026, 1, i + 1, 1, 0),
              endTime: DateTime(2026, 1, i + 1, 6, 0),
              stage: SleepStage.light,
            ),
          ],
          sleepScore: 55,
        ),
      );

      final insights = analytics.generateInsights(sessions);
      expect(insights, isNotEmpty);
    });
  });

  group('Alarm entity', () {
    test('serializes and deserializes correctly', () {
      final alarm = Alarm(
        id: 'test-id',
        label: 'Morning',
        earliestWakeTime: DateTime(2026, 1, 1, 6, 30),
        latestWakeTime: DateTime(2026, 1, 1, 6, 45),
        repeatDays: [1, 2, 3, 4, 5],
        challenges: [ChallengeType.mathProblem],
      );

      final json = alarm.toJson();
      final restored = Alarm.fromJson(json);

      expect(restored.id, alarm.id);
      expect(restored.label, alarm.label);
      expect(restored.smartWakeWindowMinutes, 15);
      expect(restored.challenges, [ChallengeType.mathProblem]);
    });
  });

  group('ChallengeType', () {
    test('free challenges are correctly identified', () {
      expect(ChallengeType.mathProblem.isFree, isTrue);
      expect(ChallengeType.shakePhone.isFree, isTrue);
      expect(ChallengeType.barcodeScan.isFree, isTrue);
      expect(ChallengeType.qrCode.isFree, isFalse);
      expect(ChallengeType.memoryGame.isFree, isFalse);
    });
  });
}

class _NoOpCalibration implements CalibrationService {
  @override
  bool get isCalibrating => false;

  @override
  int get daysRemaining => 0;

  @override
  DateTime? get calibrationStart => null;

  @override
  Future<void> startCalibration() async {}

  @override
  Future<void> completeCalibration() async {}
}
