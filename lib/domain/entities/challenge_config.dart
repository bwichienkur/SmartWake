import 'package:equatable/equatable.dart';

import 'challenge_difficulty.dart';

/// Resolved challenge parameters from difficulty + optional easy mode.
class ChallengeConfig {
  const ChallengeConfig({
    required this.difficulty,
    this.easyMode = false,
  });

  final ChallengeDifficulty difficulty;
  final bool easyMode;

  ChallengeDifficulty get effectiveDifficulty =>
      easyMode ? ChallengeDifficulty.easy : difficulty;

  int get shakeCount => switch (effectiveDifficulty) {
        ChallengeDifficulty.easy => 8,
        ChallengeDifficulty.normal => 15,
        ChallengeDifficulty.hard => 25,
      };

  int get memorySequenceLength => switch (effectiveDifficulty) {
        ChallengeDifficulty.easy => 3,
        ChallengeDifficulty.normal => 4,
        ChallengeDifficulty.hard => 6,
      };

  int get patternLength => switch (effectiveDifficulty) {
        ChallengeDifficulty.easy => 4,
        ChallengeDifficulty.normal => 5,
        ChallengeDifficulty.hard => 7,
      };

  int get requiredSteps => switch (effectiveDifficulty) {
        ChallengeDifficulty.easy => 10,
        ChallengeDifficulty.normal => 20,
        ChallengeDifficulty.hard => 35,
      };

  String get typingPhrase => switch (effectiveDifficulty) {
        ChallengeDifficulty.easy => 'I am awake',
        ChallengeDifficulty.normal => 'I am awake and ready',
        ChallengeDifficulty.hard => 'I am fully awake and ready for today',
      };
}
