class FeatureFlags {
  const FeatureFlags({
    this.calendarAwareAlarms = true,
    this.travelMode = true,
    this.aiInsights = true,
    this.windDownMode = true,
    this.lifetimePurchase = true,
    this.widgets = false,
    this.siriShortcuts = false,
  });

  final bool calendarAwareAlarms;
  final bool travelMode;
  final bool aiInsights;
  final bool windDownMode;
  final bool lifetimePurchase;
  final bool widgets;
  final bool siriShortcuts;

  static const defaults = FeatureFlags();
}
