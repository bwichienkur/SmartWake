enum ChallengeDifficulty { easy, normal, hard }

extension ChallengeDifficultyX on ChallengeDifficulty {
  String get label => switch (this) {
        ChallengeDifficulty.easy => 'Easy',
        ChallengeDifficulty.normal => 'Normal',
        ChallengeDifficulty.hard => 'Hard',
      };
}
