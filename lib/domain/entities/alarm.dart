import 'package:equatable/equatable.dart';

import 'challenge_difficulty.dart';
import 'challenge_type.dart';

class Alarm extends Equatable {
  const Alarm({
    required this.id,
    required this.label,
    required this.earliestWakeTime,
    required this.latestWakeTime,
    required this.repeatDays,
    this.isEnabled = true,
    this.isSmartWake = true,
    this.soundId = 'gentle_chime',
    this.volume = 0.8,
    this.fadeInSeconds = 30,
    this.vibrationEnabled = true,
    this.snoozeMinutes = 9,
    this.snoozeEnabled = true,
    this.challengeMode = ChallengeMode.single,
    this.challenges = const [ChallengeType.mathProblem],
    this.challengeDifficulty = ChallengeDifficulty.normal,
    this.challengeBarcodeValue,
    this.challengeQrValue,
    this.isNap = false,
    this.skipHolidays = false,
    this.skipToday = false,
    this.presetId,
    this.iconName,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String label;
  final DateTime earliestWakeTime;
  final DateTime latestWakeTime;
  final List<int> repeatDays;
  final bool isEnabled;
  final bool isSmartWake;
  final String soundId;
  final double volume;
  final int fadeInSeconds;
  final bool vibrationEnabled;
  final int snoozeMinutes;
  final bool snoozeEnabled;
  final ChallengeMode challengeMode;
  final List<ChallengeType> challenges;
  final ChallengeDifficulty challengeDifficulty;
  final String? challengeBarcodeValue;
  final String? challengeQrValue;
  final bool isNap;
  final bool skipHolidays;
  final bool skipToday;
  final String? presetId;
  final String? iconName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Duration get smartWakeWindow => latestWakeTime.difference(earliestWakeTime);
  int get smartWakeWindowMinutes => smartWakeWindow.inMinutes;

  Alarm copyWith({
    String? id,
    String? label,
    DateTime? earliestWakeTime,
    DateTime? latestWakeTime,
    List<int>? repeatDays,
    bool? isEnabled,
    bool? isSmartWake,
    String? soundId,
    double? volume,
    int? fadeInSeconds,
    bool? vibrationEnabled,
    int? snoozeMinutes,
    bool? snoozeEnabled,
    ChallengeMode? challengeMode,
    List<ChallengeType>? challenges,
    ChallengeDifficulty? challengeDifficulty,
    String? challengeBarcodeValue,
    String? challengeQrValue,
    bool? isNap,
    bool? skipHolidays,
    bool? skipToday,
    String? presetId,
    String? iconName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Alarm(
      id: id ?? this.id,
      label: label ?? this.label,
      earliestWakeTime: earliestWakeTime ?? this.earliestWakeTime,
      latestWakeTime: latestWakeTime ?? this.latestWakeTime,
      repeatDays: repeatDays ?? this.repeatDays,
      isEnabled: isEnabled ?? this.isEnabled,
      isSmartWake: isSmartWake ?? this.isSmartWake,
      soundId: soundId ?? this.soundId,
      volume: volume ?? this.volume,
      fadeInSeconds: fadeInSeconds ?? this.fadeInSeconds,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      snoozeEnabled: snoozeEnabled ?? this.snoozeEnabled,
      challengeMode: challengeMode ?? this.challengeMode,
      challenges: challenges ?? this.challenges,
      challengeDifficulty: challengeDifficulty ?? this.challengeDifficulty,
      challengeBarcodeValue:
          challengeBarcodeValue ?? this.challengeBarcodeValue,
      challengeQrValue: challengeQrValue ?? this.challengeQrValue,
      isNap: isNap ?? this.isNap,
      skipHolidays: skipHolidays ?? this.skipHolidays,
      skipToday: skipToday ?? this.skipToday,
      presetId: presetId ?? this.presetId,
      iconName: iconName ?? this.iconName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'earliestWakeTime': earliestWakeTime.toIso8601String(),
        'latestWakeTime': latestWakeTime.toIso8601String(),
        'repeatDays': repeatDays,
        'isEnabled': isEnabled,
        'isSmartWake': isSmartWake,
        'soundId': soundId,
        'volume': volume,
        'fadeInSeconds': fadeInSeconds,
        'vibrationEnabled': vibrationEnabled,
        'snoozeMinutes': snoozeMinutes,
        'snoozeEnabled': snoozeEnabled,
        'challengeMode': challengeMode.name,
        'challenges': challenges.map((c) => c.name).toList(),
        'challengeDifficulty': challengeDifficulty.name,
        'challengeBarcodeValue': challengeBarcodeValue,
        'challengeQrValue': challengeQrValue,
        'isNap': isNap,
        'skipHolidays': skipHolidays,
        'skipToday': skipToday,
        'presetId': presetId,
        'iconName': iconName,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory Alarm.fromJson(Map<String, dynamic> json) => Alarm(
        id: json['id'] as String,
        label: json['label'] as String? ?? 'Alarm',
        earliestWakeTime: DateTime.parse(json['earliestWakeTime'] as String),
        latestWakeTime: DateTime.parse(json['latestWakeTime'] as String),
        repeatDays: (json['repeatDays'] as List<dynamic>)
            .map((e) => e as int)
            .toList(),
        isEnabled: json['isEnabled'] as bool? ?? true,
        isSmartWake: json['isSmartWake'] as bool? ?? true,
        soundId: json['soundId'] as String? ?? 'gentle_chime',
        volume: (json['volume'] as num?)?.toDouble() ?? 0.8,
        fadeInSeconds: json['fadeInSeconds'] as int? ?? 30,
        vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
        snoozeMinutes: json['snoozeMinutes'] as int? ?? 9,
        snoozeEnabled: json['snoozeEnabled'] as bool? ?? true,
        challengeMode: ChallengeMode.values.firstWhere(
          (m) => m.name == json['challengeMode'],
          orElse: () => ChallengeMode.single,
        ),
        challenges: (json['challenges'] as List<dynamic>?)
                ?.map(
                  (c) => ChallengeType.values.firstWhere(
                    (t) => t.name == c,
                    orElse: () => ChallengeType.mathProblem,
                  ),
                )
                .toList() ??
            [ChallengeType.mathProblem],
        challengeDifficulty: ChallengeDifficulty.values.firstWhere(
          (d) => d.name == json['challengeDifficulty'],
          orElse: () => ChallengeDifficulty.normal,
        ),
        challengeBarcodeValue: json['challengeBarcodeValue'] as String?,
        challengeQrValue: json['challengeQrValue'] as String?,
        isNap: json['isNap'] as bool? ?? false,
        skipHolidays: json['skipHolidays'] as bool? ?? false,
        skipToday: json['skipToday'] as bool? ?? false,
        presetId: json['presetId'] as String?,
        iconName: json['iconName'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
      );

  @override
  List<Object?> get props => [
        id,
        label,
        earliestWakeTime,
        latestWakeTime,
        repeatDays,
        isEnabled,
        isSmartWake,
        skipToday,
      ];
}

enum AlarmRingState {
  idle,
  ringing,
  countdown,
  challengeActive,
  snoozed,
  dismissed,
}

enum AlarmArmedStatus { armed, noAlarms, disabled }

AlarmArmedStatus armedStatusFor(List<Alarm> alarms) {
  final enabled = alarms.where((a) => a.isEnabled && !a.skipToday).toList();
  if (enabled.isEmpty) {
    return alarms.isEmpty ? AlarmArmedStatus.noAlarms : AlarmArmedStatus.disabled;
  }
  return AlarmArmedStatus.armed;
}
