import 'package:equatable/equatable.dart';

import 'sleep_stage.dart';

class SleepSegment extends Equatable {
  const SleepSegment({
    required this.startTime,
    required this.endTime,
    required this.stage,
    this.heartRate,
    this.hrv,
    this.movementScore,
    this.source = SensorSource.estimated,
  });

  final DateTime startTime;
  final DateTime endTime;
  final SleepStage stage;
  final double? heartRate;
  final double? hrv;
  final double? movementScore;
  final SensorSource source;

  Duration get duration => endTime.difference(startTime);

  Map<String, dynamic> toJson() => {
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'stage': stage.name,
        'heartRate': heartRate,
        'hrv': hrv,
        'movementScore': movementScore,
        'source': source.name,
      };

  factory SleepSegment.fromJson(Map<String, dynamic> json) => SleepSegment(
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
        stage: SleepStage.values.firstWhere(
          (s) => s.name == json['stage'],
          orElse: () => SleepStage.unknown,
        ),
        heartRate: (json['heartRate'] as num?)?.toDouble(),
        hrv: (json['hrv'] as num?)?.toDouble(),
        movementScore: (json['movementScore'] as num?)?.toDouble(),
        source: SensorSource.values.firstWhere(
          (s) => s.name == json['source'],
          orElse: () => SensorSource.estimated,
        ),
      );

  @override
  List<Object?> get props =>
      [startTime, endTime, stage, heartRate, hrv, movementScore, source];
}

class SleepSession extends Equatable {
  const SleepSession({
    required this.id,
    required this.bedTime,
    required this.wakeTime,
    required this.segments,
    this.sleepScore,
    this.sleepEfficiency,
    this.wakeQuality,
    this.consistencyScore,
    this.alarmId,
    this.wasSmartWake,
    this.actualWakeStage,
    this.insights = const [],
  });

  final String id;
  final DateTime bedTime;
  final DateTime wakeTime;
  final List<SleepSegment> segments;
  final int? sleepScore;
  final double? sleepEfficiency;
  final double? wakeQuality;
  final double? consistencyScore;
  final String? alarmId;
  final bool? wasSmartWake;
  final SleepStage? actualWakeStage;
  final List<String> insights;

  Duration get totalSleep => wakeTime.difference(bedTime);

  Duration get deepSleep => _stageDuration(SleepStage.deep);
  Duration get lightSleep => _stageDuration(SleepStage.light);
  Duration get remSleep => _stageDuration(SleepStage.rem);
  Duration get awakeTime => _stageDuration(SleepStage.awake);

  Duration _stageDuration(SleepStage stage) {
    return segments
        .where((s) => s.stage == stage)
        .fold(Duration.zero, (sum, s) => sum + s.duration);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bedTime': bedTime.toIso8601String(),
        'wakeTime': wakeTime.toIso8601String(),
        'segments': segments.map((s) => s.toJson()).toList(),
        'sleepScore': sleepScore,
        'sleepEfficiency': sleepEfficiency,
        'wakeQuality': wakeQuality,
        'consistencyScore': consistencyScore,
        'alarmId': alarmId,
        'wasSmartWake': wasSmartWake,
        'actualWakeStage': actualWakeStage?.name,
        'insights': insights,
      };

  factory SleepSession.fromJson(Map<String, dynamic> json) => SleepSession(
        id: json['id'] as String,
        bedTime: DateTime.parse(json['bedTime'] as String),
        wakeTime: DateTime.parse(json['wakeTime'] as String),
        segments: (json['segments'] as List<dynamic>)
            .map((s) => SleepSegment.fromJson(s as Map<String, dynamic>))
            .toList(),
        sleepScore: json['sleepScore'] as int?,
        sleepEfficiency: (json['sleepEfficiency'] as num?)?.toDouble(),
        wakeQuality: (json['wakeQuality'] as num?)?.toDouble(),
        consistencyScore: (json['consistencyScore'] as num?)?.toDouble(),
        alarmId: json['alarmId'] as String?,
        wasSmartWake: json['wasSmartWake'] as bool?,
        actualWakeStage: json['actualWakeStage'] != null
            ? SleepStage.values.firstWhere(
                (s) => s.name == json['actualWakeStage'],
              )
            : null,
        insights: (json['insights'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );

  @override
  List<Object?> get props => [id, bedTime, wakeTime, segments, sleepScore];
}

class SleepInsight extends Equatable {
  const SleepInsight({
    required this.title,
    required this.description,
    required this.category,
    this.priority = 0,
  });

  final String title;
  final String description;
  final String category;
  final int priority;

  @override
  List<Object?> get props => [title, description, category, priority];
}

class BedtimeRecommendation extends Equatable {
  const BedtimeRecommendation({
    required this.recommendedBedtime,
    required this.targetWakeTime,
    required this.reason,
    required this.estimatedSleepDuration,
  });

  final DateTime recommendedBedtime;
  final DateTime targetWakeTime;
  final String reason;
  final Duration estimatedSleepDuration;

  @override
  List<Object?> get props =>
      [recommendedBedtime, targetWakeTime, reason, estimatedSleepDuration];
}
