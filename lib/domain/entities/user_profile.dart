import 'package:equatable/equatable.dart';

enum SubscriptionTier { free, premium, trial, lifetime }

enum AuthProvider { guest, email, google, apple }

class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    this.displayName,
    this.email,
    this.photoUrl,
    this.authProvider = AuthProvider.guest,
    this.subscriptionTier = SubscriptionTier.free,
    this.trialEndsAt,
    this.createdAt,
    this.preferences = const UserPreferences(),
  });

  final String id;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final AuthProvider authProvider;
  final SubscriptionTier subscriptionTier;
  final DateTime? trialEndsAt;
  final DateTime? createdAt;
  final UserPreferences preferences;

  bool get isPremium =>
      subscriptionTier == SubscriptionTier.premium ||
      subscriptionTier == SubscriptionTier.trial ||
      subscriptionTier == SubscriptionTier.lifetime;

  bool get isTrialActive =>
      subscriptionTier == SubscriptionTier.trial &&
      trialEndsAt != null &&
      trialEndsAt!.isAfter(DateTime.now());

  UserProfile copyWith({
    String? id,
    String? displayName,
    String? email,
    String? photoUrl,
    AuthProvider? authProvider,
    SubscriptionTier? subscriptionTier,
    DateTime? trialEndsAt,
    DateTime? createdAt,
    UserPreferences? preferences,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      authProvider: authProvider ?? this.authProvider,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      trialEndsAt: trialEndsAt ?? this.trialEndsAt,
      createdAt: createdAt ?? this.createdAt,
      preferences: preferences ?? this.preferences,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'email': email,
        'photoUrl': photoUrl,
        'authProvider': authProvider.name,
        'subscriptionTier': subscriptionTier.name,
        'trialEndsAt': trialEndsAt?.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
        'preferences': preferences.toJson(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        displayName: json['displayName'] as String?,
        email: json['email'] as String?,
        photoUrl: json['photoUrl'] as String?,
        authProvider: AuthProvider.values.firstWhere(
          (p) => p.name == json['authProvider'],
          orElse: () => AuthProvider.guest,
        ),
        subscriptionTier: SubscriptionTier.values.firstWhere(
          (t) => t.name == json['subscriptionTier'],
          orElse: () => SubscriptionTier.free,
        ),
        trialEndsAt: json['trialEndsAt'] != null
            ? DateTime.parse(json['trialEndsAt'] as String)
            : null,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
        preferences: json['preferences'] != null
            ? UserPreferences.fromJson(
                json['preferences'] as Map<String, dynamic>,
              )
            : const UserPreferences(),
      );

  @override
  List<Object?> get props =>
      [id, displayName, email, authProvider, subscriptionTier];
}

class UserPreferences extends Equatable {
  const UserPreferences({
    this.darkMode = true,
    this.use24HourFormat = false,
    this.hapticFeedback = true,
    this.reduceMotion = false,
    this.largeText = false,
    this.healthSyncEnabled = true,
    this.cloudSyncEnabled = false,
    this.notificationsEnabled = true,
    this.onboardingCompleted = false,
    this.easyChallengeMode = false,
    this.targetWakeHour = 7,
    this.targetWakeMinute = 0,
    this.typicalBedtimeHour = 23,
    this.typicalBedtimeMinute = 0,
    this.hasWearable = false,
    this.registeredBarcode,
    this.registeredQrCode,
    this.bedtimeReminderEnabled = false,
    this.windDownEnabled = false,
    this.travelModeEnabled = false,
    this.batteryOptimizationDismissed = false,
  });

  final bool darkMode;
  final bool use24HourFormat;
  final bool hapticFeedback;
  final bool reduceMotion;
  final bool largeText;
  final bool healthSyncEnabled;
  final bool cloudSyncEnabled;
  final bool notificationsEnabled;
  final bool onboardingCompleted;
  final bool easyChallengeMode;
  final int targetWakeHour;
  final int targetWakeMinute;
  final int typicalBedtimeHour;
  final int typicalBedtimeMinute;
  final bool hasWearable;
  final String? registeredBarcode;
  final String? registeredQrCode;
  final bool bedtimeReminderEnabled;
  final bool windDownEnabled;
  final bool travelModeEnabled;
  final bool batteryOptimizationDismissed;

  UserPreferences copyWith({
    bool? darkMode,
    bool? use24HourFormat,
    bool? hapticFeedback,
    bool? reduceMotion,
    bool? largeText,
    bool? healthSyncEnabled,
    bool? cloudSyncEnabled,
    bool? notificationsEnabled,
    bool? onboardingCompleted,
    bool? easyChallengeMode,
    int? targetWakeHour,
    int? targetWakeMinute,
    int? typicalBedtimeHour,
    int? typicalBedtimeMinute,
    bool? hasWearable,
    String? registeredBarcode,
    String? registeredQrCode,
    bool? bedtimeReminderEnabled,
    bool? windDownEnabled,
    bool? travelModeEnabled,
    bool? batteryOptimizationDismissed,
  }) {
    return UserPreferences(
      darkMode: darkMode ?? this.darkMode,
      use24HourFormat: use24HourFormat ?? this.use24HourFormat,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      largeText: largeText ?? this.largeText,
      healthSyncEnabled: healthSyncEnabled ?? this.healthSyncEnabled,
      cloudSyncEnabled: cloudSyncEnabled ?? this.cloudSyncEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      easyChallengeMode: easyChallengeMode ?? this.easyChallengeMode,
      targetWakeHour: targetWakeHour ?? this.targetWakeHour,
      targetWakeMinute: targetWakeMinute ?? this.targetWakeMinute,
      typicalBedtimeHour: typicalBedtimeHour ?? this.typicalBedtimeHour,
      typicalBedtimeMinute: typicalBedtimeMinute ?? this.typicalBedtimeMinute,
      hasWearable: hasWearable ?? this.hasWearable,
      registeredBarcode: registeredBarcode ?? this.registeredBarcode,
      registeredQrCode: registeredQrCode ?? this.registeredQrCode,
      bedtimeReminderEnabled:
          bedtimeReminderEnabled ?? this.bedtimeReminderEnabled,
      windDownEnabled: windDownEnabled ?? this.windDownEnabled,
      travelModeEnabled: travelModeEnabled ?? this.travelModeEnabled,
      batteryOptimizationDismissed:
          batteryOptimizationDismissed ?? this.batteryOptimizationDismissed,
    );
  }

  Map<String, dynamic> toJson() => {
        'darkMode': darkMode,
        'use24HourFormat': use24HourFormat,
        'hapticFeedback': hapticFeedback,
        'reduceMotion': reduceMotion,
        'largeText': largeText,
        'healthSyncEnabled': healthSyncEnabled,
        'cloudSyncEnabled': cloudSyncEnabled,
        'notificationsEnabled': notificationsEnabled,
        'onboardingCompleted': onboardingCompleted,
        'easyChallengeMode': easyChallengeMode,
        'targetWakeHour': targetWakeHour,
        'targetWakeMinute': targetWakeMinute,
        'typicalBedtimeHour': typicalBedtimeHour,
        'typicalBedtimeMinute': typicalBedtimeMinute,
        'hasWearable': hasWearable,
        'registeredBarcode': registeredBarcode,
        'registeredQrCode': registeredQrCode,
        'bedtimeReminderEnabled': bedtimeReminderEnabled,
        'windDownEnabled': windDownEnabled,
        'travelModeEnabled': travelModeEnabled,
        'batteryOptimizationDismissed': batteryOptimizationDismissed,
      };

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      UserPreferences(
        darkMode: json['darkMode'] as bool? ?? true,
        use24HourFormat: json['use24HourFormat'] as bool? ?? false,
        hapticFeedback: json['hapticFeedback'] as bool? ?? true,
        reduceMotion: json['reduceMotion'] as bool? ?? false,
        largeText: json['largeText'] as bool? ?? false,
        healthSyncEnabled: json['healthSyncEnabled'] as bool? ?? true,
        cloudSyncEnabled: json['cloudSyncEnabled'] as bool? ?? false,
        notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
        onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
        easyChallengeMode: json['easyChallengeMode'] as bool? ?? false,
        targetWakeHour: json['targetWakeHour'] as int? ?? 7,
        targetWakeMinute: json['targetWakeMinute'] as int? ?? 0,
        typicalBedtimeHour: json['typicalBedtimeHour'] as int? ?? 23,
        typicalBedtimeMinute: json['typicalBedtimeMinute'] as int? ?? 0,
        hasWearable: json['hasWearable'] as bool? ?? false,
        registeredBarcode: json['registeredBarcode'] as String?,
        registeredQrCode: json['registeredQrCode'] as String?,
        bedtimeReminderEnabled:
            json['bedtimeReminderEnabled'] as bool? ?? false,
        windDownEnabled: json['windDownEnabled'] as bool? ?? false,
        travelModeEnabled: json['travelModeEnabled'] as bool? ?? false,
        batteryOptimizationDismissed:
            json['batteryOptimizationDismissed'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [darkMode, onboardingCompleted, easyChallengeMode];
}
