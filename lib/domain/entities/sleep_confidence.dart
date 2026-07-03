import 'sleep_stage.dart';

enum SleepConfidence { high, medium, low }

extension SleepConfidenceX on SleepConfidence {
  String get label => switch (this) {
        SleepConfidence.high => 'High confidence',
        SleepConfidence.medium => 'Medium confidence',
        SleepConfidence.low => 'Low confidence',
      };

  String get shortLabel => switch (this) {
        SleepConfidence.high => 'High',
        SleepConfidence.medium => 'Medium',
        SleepConfidence.low => 'Low',
      };
}

class SleepStageEstimate {
  const SleepStageEstimate({
    required this.stage,
    required this.confidence,
    required this.source,
    this.calibrationActive = false,
  });

  final SleepStage stage;
  final SleepConfidence confidence;
  final SensorSource source;
  final bool calibrationActive;
}
