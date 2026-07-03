class AppConstants {
  AppConstants._();

  static const String appName = 'SmartWake';
  static const String hiveBoxName = 'smart_wake_box';
  static const String secureStorageKey = 'smart_wake_encryption_key';

  // Smart Wake
  static const int freeMaxWakeWindowMinutes = 15;
  static const int premiumMaxWakeWindowMinutes = 90;
  static const int challengeCountdownSeconds = 15;
  static const int freeSleepHistoryDays = 7;

  // Legal & support — host docs/ via GitHub Pages or your domain before submission.
  // GitHub Pages example: https://YOUR_USERNAME.github.io/smart_wake/privacy.html
  static const String privacyPolicyUrl = 'https://smartwake.app/privacy';
  static const String termsOfServiceUrl = 'https://smartwake.app/terms';
  static const String supportEmail = 'support@smartwake.app';
  static const String supportUrl = 'https://smartwake.app/support';

  // App identifiers (must match App Store Connect + Xcode)
  static const String iosBundleId = 'com.smartwake.app';
  static const String androidApplicationId = 'com.smartwake.app';
  static const String premiumMonthlyId = 'smartwake_premium_monthly';
  static const String premiumYearlyId = 'smartwake_premium_yearly';
  static const String premiumLifetimeId = 'smartwake_premium_lifetime';
  static const double premiumMonthlyPrice = 4.99;
  static const double premiumYearlyPrice = 39.99;
  static const double premiumLifetimePrice = 79.99;
  static const int trialDays = 7;

  // Disclaimer
  static const String sleepStageDisclaimer =
      'Sleep stages shown are estimates based on sensor data and are not '
      'medical-grade. SmartWake is not a medical device. Consult a healthcare '
      'professional for sleep disorders.';

  static const List<String> freeAlarmSounds = [
    'gentle_chime',
    'morning_birds',
    'soft_piano',
    'ocean_waves',
    'sunrise',
  ];

  static const List<String> freeChallengeTypes = [
    'math',
    'shake',
    'barcode',
  ];
}
