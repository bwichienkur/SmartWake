import 'package:logger/logger.dart';

/// Product analytics — swap backend (Firebase, Amplitude) without changing call sites.
class AnalyticsService {
  AnalyticsService();

  final _log = Logger(printer: PrettyPrinter(methodCount: 0));

  void track(String event, [Map<String, dynamic>? properties]) {
    _log.i('📊 $event ${properties ?? ''}');
    // TODO: forward to Firebase Analytics / Amplitude when configured
  }

  void screen(String name) => track('screen_view', {'screen': name});

  void alarmCreated({required bool isSmartWake, required int windowMinutes}) =>
      track('alarm_created', {
        'smart_wake': isSmartWake,
        'window_minutes': windowMinutes,
      });

  void alarmTriggered({required String reason, required bool wasSmartWake}) =>
      track('alarm_triggered', {
        'reason': reason,
        'smart_wake': wasSmartWake,
      });

  void challengeCompleted({
    required String type,
    required int durationSeconds,
    required bool easyMode,
  }) =>
      track('challenge_completed', {
        'type': type,
        'duration_seconds': durationSeconds,
        'easy_mode': easyMode,
      });

  void premiumViewed({required String source}) =>
      track('premium_viewed', {'source': source});

  void premiumPurchased({required String productId}) =>
      track('premium_purchased', {'product_id': productId});

  void onboardingCompleted({required bool createdAlarm}) =>
      track('onboarding_completed', {'created_alarm': createdAlarm});
}
