import '../../../domain/entities/sleep_session.dart';
import '../../../domain/entities/sleep_stage.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/repositories/repositories.dart';
import '../datasources/local/sleep_local_datasource.dart';
import '../../services/sleep/sleep_analytics_service.dart';
import '../../services/sleep/sleep_stage_estimator.dart';

class SleepRepositoryImpl implements SleepRepository {
  SleepRepositoryImpl(
    this._local,
    this._estimator,
    this._analytics,
    this._userRepository,
  );

  final SleepLocalDataSource _local;
  final SleepStageEstimator _estimator;
  final SleepAnalyticsService _analytics;
  final UserRepository _userRepository;

  @override
  Future<List<SleepSession>> getSessions({
    DateTime? from,
    DateTime? to,
  }) async {
    final user = await _userRepository.getCurrentUser();
    final sessions = await _local.getSessions(from: from, to: to);

    if (user?.isPremium != true) {
      final cutoff = DateTime.now().subtract(const Duration(days: 7));
      return sessions.where((s) => s.wakeTime.isAfter(cutoff)).toList();
    }
    return sessions;
  }

  @override
  Future<SleepSession?> getSessionById(String id) => _local.getSessionById(id);

  @override
  Future<void> saveSession(SleepSession session) =>
      _local.saveSession(session);

  @override
  Future<void> deleteSession(String id) => _local.deleteSession(id);

  @override
  Stream<SleepStage> watchCurrentSleepStage() => _estimator.watchSleepStage();

  @override
  Future<List<SleepInsight>> generateInsights({int days = 7}) async {
    final user = await _userRepository.getCurrentUser();
    if (user?.isPremium != true) return [];

    final from = DateTime.now().subtract(Duration(days: days));
    final sessions = await _local.getSessions(from: from);
    return _analytics.generateInsights(sessions);
  }

  @override
  Future<BedtimeRecommendation?> getBedtimeRecommendation() async {
    final user = await _userRepository.getCurrentUser();
    if (user?.isPremium != true) return null;

    final sessions = await _local.getSessions(
      from: DateTime.now().subtract(const Duration(days: 14)),
    );
    return _analytics.recommendBedtime(sessions);
  }
}
