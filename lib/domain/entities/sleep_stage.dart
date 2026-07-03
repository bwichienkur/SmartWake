enum SleepStage {
  awake,
  light,
  deep,
  rem,
  unknown;

  String get displayName => switch (this) {
        SleepStage.awake => 'Awake',
        SleepStage.light => 'Light Sleep',
        SleepStage.deep => 'Deep Sleep',
        SleepStage.rem => 'REM',
        SleepStage.unknown => 'Unknown',
      };

  bool get isLightSleep => this == SleepStage.light;
}

enum SensorSource {
  appleWatch,
  healthKit,
  healthConnect,
  wearOs,
  fitbit,
  garmin,
  phoneAccelerometer,
  phoneGyroscope,
  phoneHeartRate,
  estimated,
}
