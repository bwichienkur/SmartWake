import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/alarm_presets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/providers.dart';
import '../../../core/theme/app_theme.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _bedtime = const TimeOfDay(hour: 23, minute: 0);
  bool _hasWearable = false;
  bool _createFirstAlarm = true;
  bool _notificationsGranted = false;

  static const _infoPages = 4;
  int get _totalPages => _infoPages + 2; // permissions + setup

  Future<void> _requestPermissions() async {
    final status = await Permission.notification.request();
    setState(() => _notificationsGranted = status.isGranted);
  }

  Future<void> _complete() async {
    final user = await ref.read(userRepositoryProvider).getCurrentUser();
    if (user != null) {
      await ref.read(userRepositoryProvider).saveUser(
            user.copyWith(
              preferences: user.preferences.copyWith(
                onboardingCompleted: true,
                hasWearable: _hasWearable,
                targetWakeHour: _wakeTime.hour,
                targetWakeMinute: _wakeTime.minute,
                typicalBedtimeHour: _bedtime.hour,
                typicalBedtimeMinute: _bedtime.minute,
              ),
            ),
          );
      await ref.read(bedtimeReminderProvider).syncFromPreferences(
            user.preferences.copyWith(
              targetWakeHour: _wakeTime.hour,
              targetWakeMinute: _wakeTime.minute,
              typicalBedtimeHour: _bedtime.hour,
              typicalBedtimeMinute: _bedtime.minute,
            ),
          );
    }

    if (_createFirstAlarm) {
      final preset = AlarmPresets.all.first;
      final alarm = preset.toAlarm(id: const Uuid().v4()).copyWith(
            earliestWakeTime: DateTime(2026, 1, 1, _wakeTime.hour, _wakeTime.minute),
            latestWakeTime: DateTime(2026, 1, 1, _wakeTime.hour, _wakeTime.minute)
                .add(Duration(minutes: preset.windowMinutes)),
            label: 'Morning Alarm',
          );
      await ref.read(alarmEngineProvider).scheduleAlarm(alarm);
    }

    await ref.read(healthRepositoryProvider).requestPermissions();
    ref.read(analyticsProvider).onboardingCompleted(createdAlarm: _createFirstAlarm);
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final isPermissionsPage = _currentPage == _infoPages;
    final isSetupPage = _currentPage == _infoPages + 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: _complete, child: const Text('Skip')),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _info(Icons.auto_awesome, 'Smart Wake',
                      'Wake during light sleep within your window.'),
                  _info(Icons.favorite_outline, 'Sleep Insights',
                      'Track estimated stages. Not medical-grade.'),
                  _info(Icons.videogame_asset_outlined, 'Wake-Up Challenges',
                      'Prove you\'re awake with fun challenges.'),
                  _info(Icons.health_and_safety_outlined, 'Health Integration',
                      'Connect Apple Health for better estimates.'),
                  _permissionsPage(),
                  _setupPage(),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _totalPages,
                (i) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _currentPage
                        ? AppColors.primary
                        : Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  if (_currentPage == _totalPages - 1)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        AppConstants.sleepStageDisclaimer,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (isSetupPage && _createFirstAlarm)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Tomorrow, SmartWake will try to wake you around ${_wakeTime.format(context)}.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        if (_currentPage < _totalPages - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _complete();
                        }
                      },
                      child: Text(
                        isSetupPage
                            ? 'Get Started'
                            : isPermissionsPage
                                ? 'Continue'
                                : 'Next',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: AppColors.primary),
          ).animate().scale(duration: 400.ms),
          const SizedBox(height: 48),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _permissionsPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Permissions', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          Text(
            'SmartWake needs notifications to ring reliably. On Android, also disable '
            'battery optimization for SmartWake in system settings.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: Icon(
              _notificationsGranted ? Icons.check_circle : Icons.notifications_active,
              color: _notificationsGranted ? AppColors.success : null,
            ),
            title: const Text('Allow notifications'),
            subtitle: Text(_notificationsGranted ? 'Granted' : 'Required for alarms'),
            trailing: _notificationsGranted
                ? null
                : FilledButton(onPressed: _requestPermissions, child: const Text('Allow')),
          ),
          const ListTile(
            leading: Icon(Icons.battery_alert_outlined),
            title: Text('Battery optimization'),
            subtitle: Text('Settings → Apps → SmartWake → Battery → Unrestricted'),
          ),
        ],
      ),
    );
  }

  Widget _setupPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick setup', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          ListTile(
            title: const Text('Target wake time'),
            trailing: TextButton(
              onPressed: () async {
                final picked = await showTimePicker(context: context, initialTime: _wakeTime);
                if (picked != null) setState(() => _wakeTime = picked);
              },
              child: Text(_wakeTime.format(context)),
            ),
          ),
          ListTile(
            title: const Text('Typical bedtime'),
            trailing: TextButton(
              onPressed: () async {
                final picked = await showTimePicker(context: context, initialTime: _bedtime);
                if (picked != null) setState(() => _bedtime = picked);
              },
              child: Text(_bedtime.format(context)),
            ),
          ),
          SwitchListTile(
            title: const Text('I use a wearable'),
            subtitle: const Text('Apple Watch, Fitbit, etc.'),
            value: _hasWearable,
            onChanged: (v) => setState(() => _hasWearable = v),
          ),
          SwitchListTile(
            title: const Text('Create first alarm'),
            value: _createFirstAlarm,
            onChanged: (v) => setState(() => _createFirstAlarm = v),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
