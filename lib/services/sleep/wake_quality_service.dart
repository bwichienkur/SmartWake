import '../../domain/entities/sleep_stage.dart';

class WakeQualityService {
  double calculateWakeQuality({
    required Duration challengeDuration,
    required bool wasSmartWake,
    required SleepStage? wakeStage,
  }) {
    var score = 70.0;
    if (wasSmartWake) score += 15;
    if (wakeStage == SleepStage.light) score += 10;
    if (challengeDuration.inSeconds <= 30) score += 5;
    if (challengeDuration.inSeconds > 120) score -= 15;
    return score.clamp(0, 100);
  }
}
