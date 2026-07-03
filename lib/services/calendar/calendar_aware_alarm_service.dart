/// Calendar-aware alarm suggestions (Premium).
/// Wire to device calendar / Google Calendar API in production.
class CalendarAwareAlarmService {
  Future<DateTime?> suggestedWakeBeforeEvent({
    Duration leadTime = const Duration(minutes: 90),
  }) async {
    // Placeholder: would query calendar for next event
    final now = DateTime.now();
    final tomorrowMorning = DateTime(now.year, now.month, now.day + 1, 8);
    return tomorrowMorning.subtract(leadTime);
  }

  Future<bool> hasUpcomingEventToday() async => false;
}
