import 'package:flutter_test/flutter_test.dart';

import 'package:smart_wake/core/utils/holiday_utils.dart';
import 'package:smart_wake/domain/entities/alarm.dart';
import 'package:smart_wake/domain/entities/challenge_config.dart';
import 'package:smart_wake/domain/entities/challenge_difficulty.dart';

void main() {
  group('holiday_utils', () {
    test('shouldSkipAlarmToday respects skipToday', () {
      final alarm = Alarm(
        id: '1',
        label: 'Test',
        earliestWakeTime: _t,
        latestWakeTime: _t,
        repeatDays: const [1],
        skipToday: true,
      );
      expect(shouldSkipAlarmToday(alarm), isTrue);
    });
  });

  group('ChallengeConfig', () {
    test('easy mode reduces shake count', () {
      const normal = ChallengeConfig(difficulty: ChallengeDifficulty.normal);
      const easy = ChallengeConfig(
        difficulty: ChallengeDifficulty.hard,
        easyMode: true,
      );
      expect(easy.shakeCount, lessThan(normal.shakeCount));
    });

    test('hard difficulty increases memory length', () {
      const easy = ChallengeConfig(difficulty: ChallengeDifficulty.easy);
      const hard = ChallengeConfig(difficulty: ChallengeDifficulty.hard);
      expect(hard.memorySequenceLength, greaterThan(easy.memorySequenceLength));
    });
  });
}

final _t = DateTime(2026, 1, 1, 7);
