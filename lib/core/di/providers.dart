import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/local/alarm_local_datasource.dart';
import '../../data/datasources/local/local_storage_service.dart';
import '../../data/datasources/local/sleep_local_datasource.dart';
import '../../data/datasources/local/user_local_datasource.dart';
import '../../data/repositories/alarm_repository_impl.dart';
import '../../data/repositories/sleep_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/repositories/repositories.dart';
import '../../services/alarm/alarm_engine.dart';
import '../../services/alarm/alarm_readiness_service.dart';
import '../../services/alarm/alarm_scheduler_service.dart';
import '../../services/alarm/notification_service.dart';
import '../../services/analytics/analytics_service.dart';
import '../../services/analytics/crash_reporting_service.dart';
import '../../services/calendar/calendar_aware_alarm_service.dart';
import '../../services/challenges/challenge_stats_service.dart';
import '../../services/engagement/bedtime_reminder_service.dart';
import '../../services/engagement/review_prompt_service.dart';
import '../../services/feature_flags/feature_flags.dart';
import '../../services/health/health_service.dart';
import '../../services/sensors/phone_sensor_service.dart';
import '../../services/sleep/calibration_service.dart';
import '../../services/sleep/sleep_analytics_service.dart';
import '../../services/sleep/sleep_stage_estimator.dart';
import '../../services/sleep/wake_quality_service.dart';
import '../../services/subscription/subscription_service.dart';
import '../../services/sync/sync_service.dart';
import '../../services/travel/travel_mode_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

final localStorageProvider = Provider<LocalStorageService>((ref) {
  throw UnimplementedError('Must be overridden in main');
});

final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());
final featureFlagsProvider = Provider<FeatureFlags>((ref) => FeatureFlags.defaults);
final analyticsProvider = Provider<AnalyticsService>((ref) => AnalyticsService());
final crashReportingProvider = Provider<CrashReportingService>((ref) => CrashReportingService());

final alarmLocalDataSourceProvider = Provider<AlarmLocalDataSource>((ref) {
  return AlarmLocalDataSource(ref.watch(localStorageProvider));
});

final sleepLocalDataSourceProvider = Provider<SleepLocalDataSource>((ref) {
  return SleepLocalDataSource(ref.watch(localStorageProvider));
});

final userLocalDataSourceProvider = Provider<UserLocalDataSource>((ref) {
  return UserLocalDataSource(ref.watch(localStorageProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(ref.watch(userLocalDataSourceProvider));
});

final phoneSensorProvider = Provider<PhoneSensorService>((ref) {
  final service = PhoneSensorService();
  ref.onDispose(service.dispose);
  return service;
});

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  return HealthService(ref.watch(phoneSensorProvider));
});

final calibrationServiceProvider = Provider<CalibrationService>((ref) {
  return CalibrationService(ref.watch(localStorageProvider));
});

final sleepStageEstimatorProvider = Provider<SleepStageEstimator>((ref) {
  final estimator = SleepStageEstimator(
    ref.watch(healthRepositoryProvider),
    ref.watch(phoneSensorProvider),
    ref.watch(calibrationServiceProvider),
  );
  ref.onDispose(estimator.dispose);
  return estimator;
});

final sleepAnalyticsProvider = Provider<SleepAnalyticsService>((ref) {
  return SleepAnalyticsService();
});

final wakeQualityProvider = Provider<WakeQualityService>((ref) => WakeQualityService());

final alarmRepositoryProvider = Provider<AlarmRepository>((ref) {
  return AlarmRepositoryImpl(ref.watch(alarmLocalDataSourceProvider));
});

final sleepRepositoryProvider = Provider<SleepRepository>((ref) {
  return SleepRepositoryImpl(
    ref.watch(sleepLocalDataSourceProvider),
    ref.watch(sleepStageEstimatorProvider),
    ref.watch(sleepAnalyticsProvider),
    ref.watch(userRepositoryProvider),
  );
});

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncService(
    ref.watch(alarmLocalDataSourceProvider),
    ref.watch(sleepLocalDataSourceProvider),
    ref.watch(userLocalDataSourceProvider),
    ref.watch(connectivityProvider),
  );
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final alarmSchedulerProvider = Provider<AlarmSchedulerService>((ref) {
  return AlarmSchedulerService(ref.watch(notificationServiceProvider));
});

final alarmReadinessServiceProvider = Provider<AlarmReadinessService>((ref) {
  return AlarmReadinessService();
});

final alarmReadinessProvider = FutureProvider((ref) {
  return ref.watch(alarmReadinessServiceProvider).check();
});

final challengeStatsProvider = Provider<ChallengeStatsService>((ref) {
  return ChallengeStatsService(ref.watch(localStorageProvider));
});

final reviewPromptProvider = Provider<ReviewPromptService>((ref) {
  return ReviewPromptService(ref.watch(localStorageProvider));
});

final bedtimeReminderProvider = Provider<BedtimeReminderService>((ref) {
  return BedtimeReminderService(ref.watch(notificationServiceProvider));
});

final travelModeProvider = Provider<TravelModeService>((ref) {
  return TravelModeService(ref.watch(localStorageProvider));
});

final calendarAlarmProvider = Provider<CalendarAwareAlarmService>((ref) {
  return CalendarAwareAlarmService();
});

final alarmEngineProvider = ChangeNotifierProvider<AlarmEngine>((ref) {
  return AlarmEngine(
    sleepEstimator: ref.watch(sleepStageEstimatorProvider),
    alarmRepository: ref.watch(alarmRepositoryProvider),
    scheduler: ref.watch(alarmSchedulerProvider),
    analytics: ref.watch(analyticsProvider),
    challengeStats: ref.watch(challengeStatsProvider),
    reviewPrompt: ref.watch(reviewPromptProvider),
  );
});

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  final service = SubscriptionService(ref.watch(userRepositoryProvider));
  ref.onDispose(service.dispose);
  return service;
});

final alarmsProvider = StreamProvider((ref) {
  return ref.watch(alarmRepositoryProvider).watchAlarms();
});

final userProvider = StreamProvider((ref) {
  return ref.watch(userRepositoryProvider).watchUser();
});

final subscriptionTierProvider = StreamProvider((ref) {
  return ref.watch(subscriptionServiceProvider).watchSubscriptionTier();
});

final sleepSessionsProvider = FutureProvider((ref) {
  return ref.watch(sleepRepositoryProvider).getSessions();
});

final challengeStatsStateProvider = Provider((ref) {
  return ref.watch(challengeStatsProvider).stats;
});

final calibrationStateProvider = Provider((ref) {
  final cal = ref.watch(calibrationServiceProvider);
  return (isCalibrating: cal.isCalibrating, daysRemaining: cal.daysRemaining);
});
