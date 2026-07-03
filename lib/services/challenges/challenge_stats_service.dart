import '../../data/datasources/local/local_storage_service.dart';

class ChallengeStats {
  const ChallengeStats({
    this.totalCompleted = 0,
    this.firstTryStreak = 0,
    this.bestStreak = 0,
    this.lastCompletedAt,
  });

  final int totalCompleted;
  final int firstTryStreak;
  final int bestStreak;
  final DateTime? lastCompletedAt;

  ChallengeStats copyWith({
    int? totalCompleted,
    int? firstTryStreak,
    int? bestStreak,
    DateTime? lastCompletedAt,
  }) =>
      ChallengeStats(
        totalCompleted: totalCompleted ?? this.totalCompleted,
        firstTryStreak: firstTryStreak ?? this.firstTryStreak,
        bestStreak: bestStreak ?? this.bestStreak,
        lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      );

  Map<String, dynamic> toJson() => {
        'totalCompleted': totalCompleted,
        'firstTryStreak': firstTryStreak,
        'bestStreak': bestStreak,
        'lastCompletedAt': lastCompletedAt?.toIso8601String(),
      };

  factory ChallengeStats.fromJson(Map<String, dynamic> json) => ChallengeStats(
        totalCompleted: json['totalCompleted'] as int? ?? 0,
        firstTryStreak: json['firstTryStreak'] as int? ?? 0,
        bestStreak: json['bestStreak'] as int? ?? 0,
        lastCompletedAt: json['lastCompletedAt'] != null
            ? DateTime.parse(json['lastCompletedAt'] as String)
            : null,
      );
}

class ChallengeStatsService {
  ChallengeStatsService(this._storage);

  static const _key = 'challenge_stats';

  final LocalStorageService _storage;

  ChallengeStats get stats {
    final data = _storage.get(_key);
    if (data == null) return const ChallengeStats();
    return ChallengeStats.fromJson(data);
  }

  Future<void> recordCompletion({required bool firstTry}) async {
    final current = stats;
    final streak = firstTry ? current.firstTryStreak + 1 : 0;
    await _storage.put(
      _key,
      current
          .copyWith(
            totalCompleted: current.totalCompleted + 1,
            firstTryStreak: streak,
            bestStreak: streak > current.bestStreak ? streak : current.bestStreak,
            lastCompletedAt: DateTime.now(),
          )
          .toJson(),
    );
  }
}
