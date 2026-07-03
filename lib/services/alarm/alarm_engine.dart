import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';

import '../../domain/entities/sleep_confidence.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/alarm_sound.dart';
import '../../domain/entities/alarm.dart';
import '../../domain/entities/challenge_type.dart';
import '../../domain/repositories/repositories.dart';
import '../analytics/analytics_service.dart';
import '../challenges/challenge_stats_service.dart';
import '../engagement/review_prompt_service.dart';
import '../../core/utils/holiday_utils.dart';
import '../sleep/sleep_stage_estimator.dart';
import 'alarm_scheduler_service.dart';

class AlarmEngine extends ChangeNotifier {
  AlarmEngine({
    required SleepStageEstimator sleepEstimator,
    required AlarmRepository alarmRepository,
    required AlarmSchedulerService scheduler,
    required AnalyticsService analytics,
    required ChallengeStatsService challengeStats,
    required ReviewPromptService reviewPrompt,
  })  : _sleepEstimator = sleepEstimator,
        _alarmRepository = alarmRepository,
        _scheduler = scheduler,
        _analytics = analytics,
        _challengeStats = challengeStats,
        _reviewPrompt = reviewPrompt;

  final SleepStageEstimator _sleepEstimator;
  final AlarmRepository _alarmRepository;
  final AlarmSchedulerService _scheduler;
  final AnalyticsService _analytics;
  final ChallengeStatsService _challengeStats;
  final ReviewPromptService _reviewPrompt;

  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _smartWakeTimer;
  Timer? _countdownTimer;
  Timer? _fadeTimer;
  DateTime? _challengeStartedAt;
  bool _challengeFailedOnce = false;

  Alarm? _activeAlarm;
  AlarmRingState _ringState = AlarmRingState.idle;
  int _countdownSeconds = AppConstants.challengeCountdownSeconds;
  List<ChallengeType> _pendingChallenges = [];
  int _currentChallengeIndex = 0;

  Alarm? get activeAlarm => _activeAlarm;
  AlarmRingState get ringState => _ringState;
  int get countdownSeconds => _countdownSeconds;
  int get currentChallengeNumber => _currentChallengeIndex + 1;
  int get totalChallenges => _pendingChallenges.length;
  ChallengeType? get currentChallenge =>
      _pendingChallenges.isNotEmpty &&
              _currentChallengeIndex < _pendingChallenges.length
          ? _pendingChallenges[_currentChallengeIndex]
          : null;
  bool get hasMoreChallenges =>
      _currentChallengeIndex < _pendingChallenges.length - 1;

  Future<void> bootstrap() async {
    final alarms = await _alarmRepository.getAlarms();
    await _scheduler.rescheduleAll(alarms);
    for (final alarm in alarms.where((a) => a.isEnabled)) {
      _scheduleSmartWakeMonitoring(alarm);
    }
    notifyListeners();
  }

  AlarmArmedStatus getArmedStatus(List<Alarm> alarms) => armedStatusFor(alarms);

  Alarm? getNextAlarm(List<Alarm> alarms) {
    final enabled = alarms.where((a) => a.isEnabled && !a.skipToday).toList();
    if (enabled.isEmpty) return null;
    enabled.sort((a, b) => a.latestWakeTime.compareTo(b.latestWakeTime));
    return enabled.first;
  }

  Future<void> scheduleAlarm(Alarm alarm) async {
    await _alarmRepository.saveAlarm(alarm);
    await _scheduler.scheduleAlarm(alarm);
    if (alarm.isEnabled) _scheduleSmartWakeMonitoring(alarm);
    _analytics.alarmCreated(
      isSmartWake: alarm.isSmartWake,
      windowMinutes: alarm.smartWakeWindowMinutes,
    );
  }

  Future<void> skipAlarmToday(String alarmId) async {
    final alarm = await _alarmRepository.getAlarmById(alarmId);
    if (alarm == null) return;
    await scheduleAlarm(alarm.copyWith(skipToday: true));
  }

  void _scheduleSmartWakeMonitoring(Alarm alarm) {
    _smartWakeTimer?.cancel();
    if (alarm.skipToday) return;
    if (shouldSkipAlarmToday(alarm)) return;

    final now = DateTime.now();
    final windowStart = _nextOccurrence(alarm.earliestWakeTime);
    final windowEnd = _nextOccurrence(alarm.latestWakeTime);
    if (windowEnd.isBefore(now)) return;

    final delayUntilWindow = windowStart.difference(now);
    if (delayUntilWindow.isNegative) {
      _startSmartWakeWindow(alarm, windowEnd);
    } else {
      _smartWakeTimer = Timer(delayUntilWindow, () {
        _startSmartWakeWindow(alarm, windowEnd);
      });
    }
  }

  void _startSmartWakeWindow(Alarm alarm, DateTime windowEnd) {
    _activeAlarm = alarm;
    _sleepEstimator.startMonitoring();

    _smartWakeTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (DateTime.now().isAfter(windowEnd)) {
        timer.cancel();
        await triggerAlarm(reason: 'Latest wake time reached');
        return;
      }
      if (alarm.isSmartWake) {
        final estimate = await _sleepEstimator.estimateWithConfidence();
        if (estimate.stage.isLightSleep &&
            estimate.confidence != SleepConfidence.low) {
          timer.cancel();
          await triggerAlarm(reason: 'Light sleep detected');
        }
      }
    });
  }

  DateTime _nextOccurrence(DateTime time) {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (next.isBefore(now)) next = next.add(const Duration(days: 1));
    return next;
  }

  Future<void> triggerAlarm({String? reason}) async {
    if (_activeAlarm == null) return;

    _ringState = AlarmRingState.ringing;
    notifyListeners();
    _analytics.alarmTriggered(
      reason: reason ?? 'manual',
      wasSmartWake: _activeAlarm!.isSmartWake,
    );

    await _playAlarmSound();
    if (_activeAlarm!.vibrationEnabled) await _startVibration();

    await Future<void>.delayed(const Duration(seconds: 3));
    await _silenceAlarm();
    _startChallengeCountdown();
  }

  Future<void> _playAlarmSound() async {
    final alarm = _activeAlarm!;
    try {
      await _audioPlayer.setVolume(alarm.volume);
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource(alarmSoundAssetPath(alarm.soundId)));
      if (alarm.fadeInSeconds > 0) {
        var currentVolume = 0.0;
        final step = alarm.volume / (alarm.fadeInSeconds * 10);
        _fadeTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
          currentVolume = min(currentVolume + step, alarm.volume);
          _audioPlayer.setVolume(currentVolume);
          if (currentVolume >= alarm.volume) t.cancel();
        });
      }
    } catch (_) {}
  }

  Future<void> _startVibration() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [0, 500, 200, 500], repeat: 0);
    }
  }

  Future<void> _silenceAlarm() async {
    await _audioPlayer.stop();
    _fadeTimer?.cancel();
    if (await Vibration.hasVibrator() ?? false) Vibration.cancel();
  }

  void _startChallengeCountdown() {
    _ringState = AlarmRingState.countdown;
    _countdownSeconds = AppConstants.challengeCountdownSeconds;
    _prepareChallenges();
    notifyListeners();

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _countdownSeconds--;
      notifyListeners();
      if (_countdownSeconds <= 0) {
        timer.cancel();
        _resumeAlarm();
      }
    });
  }

  void _prepareChallenges() {
    final alarm = _activeAlarm!;
    switch (alarm.challengeMode) {
      case ChallengeMode.single:
        _pendingChallenges = [alarm.challenges.first];
      case ChallengeMode.sequence:
        _pendingChallenges = List.from(alarm.challenges);
      case ChallengeMode.random:
        _pendingChallenges = [
          alarm.challenges[Random().nextInt(alarm.challenges.length)],
        ];
    }
    _currentChallengeIndex = 0;
    _challengeFailedOnce = false;
  }

  Future<void> _resumeAlarm() async {
    if (_ringState == AlarmRingState.challengeActive) return;
    _challengeFailedOnce = true;
    _ringState = AlarmRingState.ringing;
    notifyListeners();
    await _playAlarmSound();
    if (_activeAlarm!.vibrationEnabled) await _startVibration();
  }

  void startChallenge() {
    _countdownTimer?.cancel();
    _ringState = AlarmRingState.challengeActive;
    _challengeStartedAt = DateTime.now();
    notifyListeners();
  }

  Future<void> completeChallenge() async {
    if (hasMoreChallenges) {
      _currentChallengeIndex++;
      _challengeStartedAt = DateTime.now();
      notifyListeners();
    } else {
      final duration = _challengeStartedAt != null
          ? DateTime.now().difference(_challengeStartedAt!)
          : Duration.zero;
      _analytics.challengeCompleted(
        type: currentChallenge?.name ?? 'unknown',
        durationSeconds: duration.inSeconds,
        easyMode: _activeAlarm?.challengeDifficulty.name == 'easy',
      );
      await _challengeStats.recordCompletion(firstTry: !_challengeFailedOnce);
      await _reviewPrompt.recordSuccessfulWake();
      await dismissAlarm();
    }
  }

  Future<void> dismissAlarm() async {
    await _silenceAlarm();
    _ringState = AlarmRingState.dismissed;
    _smartWakeTimer?.cancel();
    _countdownTimer?.cancel();
    _sleepEstimator.stopMonitoring();
    _activeAlarm = null;
    notifyListeners();
  }

  Future<void> snooze() async {
    if (_activeAlarm == null || !_activeAlarm!.snoozeEnabled) return;
    await _silenceAlarm();
    _ringState = AlarmRingState.snoozed;
    notifyListeners();
    _smartWakeTimer = Timer(
      Duration(minutes: _activeAlarm!.snoozeMinutes),
      () => triggerAlarm(reason: 'Snooze ended'),
    );
  }

  @override
  void dispose() {
    _smartWakeTimer?.cancel();
    _countdownTimer?.cancel();
    _fadeTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
