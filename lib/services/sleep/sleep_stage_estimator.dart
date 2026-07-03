import 'dart:async';
import 'dart:math';

import '../../domain/entities/sleep_confidence.dart';
import '../../domain/entities/sleep_session.dart';
import '../../domain/entities/sleep_stage.dart';
import '../../domain/repositories/repositories.dart';
import '../sensors/phone_sensor_service.dart';
import 'calibration_service.dart';

class SleepStageEstimator {
  SleepStageEstimator(
    this._healthRepo,
    this._phoneSensors,
    this._calibration,
  );

  final HealthRepository _healthRepo;
  final PhoneSensorService _phoneSensors;
  final CalibrationService _calibration;

  final _stageController = StreamController<SleepStage>.broadcast();
  Timer? _monitorTimer;
  SleepStage _currentStage = SleepStage.unknown;
  SleepStageEstimate? _lastEstimate;

  Stream<SleepStage> watchSleepStage() => _stageController.stream;
  SleepStage get currentStage => _currentStage;
  SleepStageEstimate? get lastEstimate => _lastEstimate;

  void startMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _estimateStage(),
    );
  }

  void stopMonitoring() => _monitorTimer?.cancel();

  Future<void> _estimateStage() async {
    final estimate = await estimateWithConfidence();
    if (estimate.stage != _currentStage) {
      _currentStage = estimate.stage;
      _stageController.add(estimate.stage);
    }
  }

  Future<SleepStage> estimateCurrentStage() async =>
      (await estimateWithConfidence()).stage;

  Future<SleepStageEstimate> estimateWithConfidence() async {
    final heartRate = await _healthRepo.getHeartRate();
    final hrv = await _healthRepo.getHrv();
    final movement = await _healthRepo.getMovementScore();
    final source = await _healthRepo.getActiveSensorSource();
    final isWearable = source != SensorSource.phoneAccelerometer &&
        source != SensorSource.phoneGyroscope &&
        source != SensorSource.estimated;

    final stage = _classifyStage(
      heartRate: heartRate,
      hrv: hrv,
      movement: movement,
      wearableBoost: isWearable,
    );

    final confidence = _confidenceFor(
      heartRate: heartRate,
      hrv: hrv,
      isWearable: isWearable,
    );

    _lastEstimate = SleepStageEstimate(
      stage: stage,
      confidence: confidence,
      source: source,
      calibrationActive: _calibration.isCalibrating,
    );
    return _lastEstimate!;
  }

  SleepConfidence _confidenceFor({
    double? heartRate,
    double? hrv,
    required bool isWearable,
  }) {
    if (isWearable && heartRate != null && hrv != null) {
      return SleepConfidence.high;
    }
    if (isWearable || heartRate != null) return SleepConfidence.medium;
    return SleepConfidence.low;
  }

  SleepStage _classifyStage({
    double? heartRate,
    double? hrv,
    required double movement,
    bool wearableBoost = false,
  }) {
    if (_calibration.isCalibrating) {
      // Conservative during calibration week
      return movement > 0.5 ? SleepStage.awake : SleepStage.light;
    }
    if (movement > 0.7) return SleepStage.awake;
    if (movement > 0.3) {
      if (heartRate != null && heartRate > 55 && heartRate < 70) {
        return SleepStage.light;
      }
      return SleepStage.awake;
    }
    if (heartRate != null) {
      if (heartRate < 50) return SleepStage.deep;
      if (heartRate >= 50 && heartRate <= 65) {
        if (hrv != null && hrv > 40) return SleepStage.rem;
        return SleepStage.light;
      }
      if (heartRate > 65 && heartRate <= 75) return SleepStage.light;
    }
    if (wearableBoost) {
      return movement < 0.15 ? SleepStage.deep : SleepStage.light;
    }
    return movement < 0.2 ? SleepStage.deep : SleepStage.light;
  }

  List<SleepSegment> generateSessionSegments({
    required DateTime bedTime,
    required DateTime wakeTime,
  }) {
    final segments = <SleepSegment>[];
    var current = bedTime;
    final random = Random(bedTime.millisecondsSinceEpoch);
    final stages = [
      SleepStage.light,
      SleepStage.deep,
      SleepStage.light,
      SleepStage.rem,
      SleepStage.light,
      SleepStage.deep,
      SleepStage.rem,
      SleepStage.light,
    ];

    while (current.isBefore(wakeTime)) {
      final remaining = wakeTime.difference(current);
      final segmentDuration = Duration(
        minutes: min(
          45 + random.nextInt(60),
          remaining.inMinutes.clamp(1, 90),
        ),
      );
      final end = current.add(segmentDuration);
      final stage = stages[random.nextInt(stages.length)];

      segments.add(
        SleepSegment(
          startTime: current,
          endTime: end.isAfter(wakeTime) ? wakeTime : end,
          stage: stage,
          movementScore: random.nextDouble() * 0.3,
          source: SensorSource.estimated,
        ),
      );
      current = end.isAfter(wakeTime) ? wakeTime : end;
    }
    return segments;
  }

  void dispose() {
    _monitorTimer?.cancel();
    _stageController.close();
  }
}
