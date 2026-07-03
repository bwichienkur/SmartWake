import '../../domain/entities/alarm.dart';
import '../../domain/entities/challenge_type.dart';

enum AlarmPresetId { workday, weekend, nap, travel }

class AlarmPreset {
  const AlarmPreset({
    required this.id,
    required this.label,
    required this.icon,
    required this.earliestHour,
    required this.earliestMinute,
    required this.windowMinutes,
    required this.repeatDays,
    this.isSmartWake = true,
    this.challenges = const [ChallengeType.mathProblem],
    this.isNap = false,
  });

  final AlarmPresetId id;
  final String label;
  final String icon;
  final int earliestHour;
  final int earliestMinute;
  final int windowMinutes;
  final List<int> repeatDays;
  final bool isSmartWake;
  final List<ChallengeType> challenges;
  final bool isNap;

  Alarm toAlarm({required String id}) {
    final now = DateTime.now();
    final earliest = DateTime(
      now.year,
      now.month,
      now.day,
      earliestHour,
      earliestMinute,
    );
    return Alarm(
      id: id,
      label: label,
      earliestWakeTime: earliest,
      latestWakeTime: earliest.add(Duration(minutes: windowMinutes)),
      repeatDays: repeatDays,
      isSmartWake: isSmartWake,
      challenges: challenges,
      isNap: isNap,
      presetId: this.id.name,
      iconName: icon,
    );
  }
}

class AlarmPresets {
  AlarmPresets._();

  static const all = [
    AlarmPreset(
      id: AlarmPresetId.workday,
      label: 'Work Day',
      icon: 'work',
      earliestHour: 6,
      earliestMinute: 30,
      windowMinutes: 15,
      repeatDays: [1, 2, 3, 4, 5],
      challenges: [ChallengeType.mathProblem],
    ),
    AlarmPreset(
      id: AlarmPresetId.weekend,
      label: 'Weekend',
      icon: 'weekend',
      earliestHour: 8,
      earliestMinute: 0,
      windowMinutes: 30,
      repeatDays: [6, 7],
      challenges: [ChallengeType.shakePhone],
    ),
    AlarmPreset(
      id: AlarmPresetId.nap,
      label: 'Nap',
      icon: 'nap',
      earliestHour: 14,
      earliestMinute: 0,
      windowMinutes: 10,
      repeatDays: [],
      isNap: true,
      challenges: [ChallengeType.mathProblem],
    ),
    AlarmPreset(
      id: AlarmPresetId.travel,
      label: 'Travel',
      icon: 'flight',
      earliestHour: 7,
      earliestMinute: 0,
      windowMinutes: 20,
      repeatDays: [1, 2, 3, 4, 5, 6, 7],
      challenges: [ChallengeType.barcodeScan],
    ),
  ];
}
