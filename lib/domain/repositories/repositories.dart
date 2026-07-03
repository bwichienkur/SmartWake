import '../entities/alarm.dart';
import '../entities/sleep_session.dart';
import '../entities/sleep_stage.dart';
import '../entities/user_profile.dart';

abstract class AlarmRepository {
  Future<List<Alarm>> getAlarms();
  Future<Alarm?> getAlarmById(String id);
  Future<void> saveAlarm(Alarm alarm);
  Future<void> deleteAlarm(String id);
  Stream<List<Alarm>> watchAlarms();
}

abstract class SleepRepository {
  Future<List<SleepSession>> getSessions({DateTime? from, DateTime? to});
  Future<SleepSession?> getSessionById(String id);
  Future<void> saveSession(SleepSession session);
  Future<void> deleteSession(String id);
  Stream<SleepStage> watchCurrentSleepStage();
  Future<List<SleepInsight>> generateInsights({int days = 7});
  Future<BedtimeRecommendation?> getBedtimeRecommendation();
}

abstract class UserRepository {
  Future<UserProfile?> getCurrentUser();
  Future<void> saveUser(UserProfile user);
  Stream<UserProfile?> watchUser();
  Future<void> signOut();
}

abstract class SubscriptionRepository {
  Future<bool> isPremiumActive();
  Future<void> purchaseMonthly();
  Future<void> purchaseYearly();
  Future<void> restorePurchases();
  Stream<SubscriptionTier> watchSubscriptionTier();
}

abstract class SyncRepository {
  Future<void> syncToCloud();
  Future<void> syncFromCloud();
  Future<bool> isOnline();
}

abstract class HealthRepository {
  Future<bool> requestPermissions();
  Future<bool> isWearableConnected();
  Future<SensorSource> getActiveSensorSource();
  Future<double?> getHeartRate();
  Future<double?> getHrv();
  Future<double> getMovementScore();
}
