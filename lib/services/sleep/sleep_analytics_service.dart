import '../../domain/entities/sleep_session.dart';

class SleepAnalyticsService {
  int calculateSleepScore(SleepSession session) {
    final totalMinutes = session.totalSleep.inMinutes;
    if (totalMinutes == 0) return 0;

    var score = 50.0;

    // Duration score (7-9 hours ideal)
    final hours = totalMinutes / 60.0;
    if (hours >= 7 && hours <= 9) {
      score += 25;
    } else if (hours >= 6 && hours <= 10) {
      score += 15;
    } else {
      score += 5;
    }

    // Deep sleep (13-23% ideal)
    final deepPercent =
        session.deepSleep.inMinutes / totalMinutes;
    if (deepPercent >= 0.13 && deepPercent <= 0.23) {
      score += 15;
    } else if (deepPercent >= 0.08) {
      score += 8;
    }

    // REM sleep (20-25% ideal)
    final remPercent = session.remSleep.inMinutes / totalMinutes;
    if (remPercent >= 0.20 && remPercent <= 0.25) {
      score += 15;
    } else if (remPercent >= 0.15) {
      score += 8;
    }

    // Efficiency
    if (session.sleepEfficiency != null) {
      score += (session.sleepEfficiency! * 0.15).clamp(0, 15);
    }

    return score.round().clamp(0, 100);
  }

  double calculateEfficiency(SleepSession session) {
    final total = session.totalSleep.inMinutes;
    if (total == 0) return 0;
    final asleep = total - session.awakeTime.inMinutes;
    return (asleep / total * 100).clamp(0, 100);
  }

  double calculateConsistency(List<SleepSession> sessions) {
    if (sessions.length < 2) return 50;

    final bedtimes = sessions.map((s) {
      return s.bedTime.hour * 60 + s.bedTime.minute;
    }).toList();

    final avg = bedtimes.reduce((a, b) => a + b) / bedtimes.length;
    final variance = bedtimes
            .map((b) => (b - avg) * (b - avg))
            .reduce((a, b) => a + b) /
        bedtimes.length;
    final stdDev = variance > 0 ? variance : 0;

    // Lower std dev = higher consistency
    return (100 - stdDev / 3).clamp(0, 100);
  }

  List<SleepInsight> generateInsights(List<SleepSession> sessions) {
    if (sessions.isEmpty) return [];

    final insights = <SleepInsight>[];
    final avgScore = sessions
            .where((s) => s.sleepScore != null)
            .map((s) => s.sleepScore!)
            .fold(0, (a, b) => a + b) /
        sessions.where((s) => s.sleepScore != null).length;

    if (avgScore < 70) {
      insights.add(
        const SleepInsight(
          title: 'Room for Improvement',
          description:
              'Your average sleep score is below optimal. Try maintaining '
              'a consistent bedtime and reducing screen time before sleep.',
          category: 'general',
          priority: 2,
        ),
      );
    }

    final avgDeep = sessions
            .map((s) => s.deepSleep.inMinutes)
            .fold(0, (a, b) => a + b) /
        sessions.length;
    if (avgDeep < 60) {
      insights.add(
        const SleepInsight(
          title: 'Low Deep Sleep',
          description:
              'Your deep sleep averages less than an hour. Regular exercise '
              'and avoiding caffeine after 2 PM may help increase deep sleep.',
          category: 'deep_sleep',
          priority: 1,
        ),
      );
    }

    final consistency = calculateConsistency(sessions);
    if (consistency < 60) {
      insights.add(
        const SleepInsight(
          title: 'Inconsistent Schedule',
          description:
              'Your bedtime varies significantly. A consistent sleep schedule '
              'can improve sleep quality by up to 30%.',
          category: 'consistency',
          priority: 3,
        ),
      );
    }

    final latest = sessions.first;
    if (latest.wakeQuality != null && latest.wakeQuality! < 60) {
      insights.add(
        const SleepInsight(
          title: 'Groggy Mornings',
          description:
              'Your recent wake quality is low. Try an earlier bedtime or '
              'enable Smart Wake for a gentler alarm.',
          category: 'wake_quality',
          priority: 2,
        ),
      );
    }

    final smartWakeSessions =
        sessions.where((s) => s.wasSmartWake == true).toList();
    if (smartWakeSessions.length >= 3) {
      final avgWakeQuality = smartWakeSessions
              .where((s) => s.wakeQuality != null)
              .map((s) => s.wakeQuality!)
              .fold(0.0, (a, b) => a + b) /
          smartWakeSessions.where((s) => s.wakeQuality != null).length;
      if (avgWakeQuality >= 75) {
        insights.add(
          SleepInsight(
            title: 'Smart Wake is working',
            description:
                'Your wake quality averages ${avgWakeQuality.round()}/100 on '
                'Smart Wake days. Keep it enabled.',
            category: 'smart_wake',
            priority: 1,
          ),
        );
      }
    }

    final avgHours = sessions
            .map((s) => s.totalSleep.inMinutes / 60.0)
            .reduce((a, b) => a + b) /
        sessions.length;
    if (avgHours < 6.5) {
      insights.add(
        SleepInsight(
          title: 'Short sleep duration',
          description:
              'You average ${avgHours.toStringAsFixed(1)} hours. Most adults '
              'need 7–9 hours for optimal recovery.',
          category: 'duration',
          priority: 2,
        ),
      );
    }

    insights.sort((a, b) => b.priority.compareTo(a.priority));
    return insights;
  }

  ({int avgScore, double avgHours}) compareAverages(List<SleepSession> sessions) {
    if (sessions.isEmpty) return (avgScore: 0, avgHours: 0.0);
    final scores = sessions.where((s) => s.sleepScore != null).map((s) => s.sleepScore!).toList();
    final avgScore = scores.isEmpty ? 0 : scores.reduce((a, b) => a + b) ~/ scores.length;
    final avgHours = sessions
            .map((s) => s.totalSleep.inMinutes / 60.0)
            .reduce((a, b) => a + b) /
        sessions.length;
    return (avgScore: avgScore, avgHours: avgHours);
  }

  BedtimeRecommendation? recommendBedtime(List<SleepSession> sessions) {
    if (sessions.isEmpty) return null;

    final avgDuration = Duration(
      minutes: sessions
              .map((s) => s.totalSleep.inMinutes)
              .reduce((a, b) => a + b) ~/
          sessions.length,
    );

    final avgBedtime = sessions
        .map((s) => s.bedTime.hour * 60 + s.bedTime.minute)
        .reduce((a, b) => a + b) ~/
        sessions.length;

    final targetWake = DateTime.now().copyWith(hour: 7, minute: 0);
    final recommendedBedtime =
        targetWake.subtract(avgDuration);

    return BedtimeRecommendation(
      recommendedBedtime: recommendedBedtime,
      targetWakeTime: targetWake,
      reason:
          'Based on your average sleep duration of ${avgDuration.inHours}h '
          '${avgDuration.inMinutes % 60}m over the past ${sessions.length} nights.',
      estimatedSleepDuration: avgDuration,
    );
  }
}
