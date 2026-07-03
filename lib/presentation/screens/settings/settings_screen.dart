import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/user_profile.dart';
import '../../widgets/smart_wake_explainer.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: userAsync.when(
        data: (user) => ListView(
          children: [
            if (user != null && !user.isPremium)
              ListTile(
                leading: const Icon(Icons.star, color: AppColors.premium),
                title: const Text('Upgrade to Premium'),
                subtitle: Text(
                  '\$${AppConstants.premiumMonthlyPrice}/mo or '
                  '\$${AppConstants.premiumYearlyPrice}/yr',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/premium'),
              ),
            const Divider(),
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: user?.preferences.darkMode ?? true,
              onChanged: (v) => _updatePrefs(ref, user, darkMode: v),
            ),
            SwitchListTile(
              title: const Text('24-Hour Format'),
              value: user?.preferences.use24HourFormat ?? false,
              onChanged: (v) => _updatePrefs(ref, user, use24HourFormat: v),
            ),
            SwitchListTile(
              title: const Text('Haptic Feedback'),
              value: user?.preferences.hapticFeedback ?? true,
              onChanged: (v) => _updatePrefs(ref, user, hapticFeedback: v),
            ),
            SwitchListTile(
              title: const Text('Reduce Motion'),
              value: user?.preferences.reduceMotion ?? false,
              onChanged: (v) => _updatePrefs(ref, user, reduceMotion: v),
            ),
            SwitchListTile(
              title: const Text('Large Text'),
              value: user?.preferences.largeText ?? false,
              onChanged: (v) => _updatePrefs(ref, user, largeText: v),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Health Sync'),
              subtitle: const Text('Apple Health / Health Connect'),
              value: user?.preferences.healthSyncEnabled ?? true,
              onChanged: (v) => _updatePrefs(ref, user, healthSyncEnabled: v),
            ),
            SwitchListTile(
              title: const Text('Cloud Sync'),
              subtitle: const Text('Premium — sign in required (coming soon)'),
              value: user?.preferences.cloudSyncEnabled ?? false,
              onChanged: (v) async {
                if (v && user?.isPremium != true) {
                  context.push('/premium');
                  return;
                }
                _updatePrefs(ref, user, cloudSyncEnabled: v);
              },
            ),
            SwitchListTile(
              title: const Text('Notifications'),
              value: user?.preferences.notificationsEnabled ?? true,
              onChanged: (v) => _updatePrefs(ref, user, notificationsEnabled: v),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Easy Challenge Mode'),
              subtitle: const Text('Simpler challenges when you\'re under the weather'),
              value: user?.preferences.easyChallengeMode ?? false,
              onChanged: (v) => _updatePrefs(ref, user, easyChallengeMode: v),
            ),
            SwitchListTile(
              title: const Text('Bedtime Reminder'),
              subtitle: const Text('Daily notification at your typical bedtime'),
              value: user?.preferences.bedtimeReminderEnabled ?? false,
              onChanged: (v) async {
                if (v && user?.isPremium != true) {
                  context.push('/premium');
                  return;
                }
                await _updatePrefs(ref, user, bedtimeReminderEnabled: v);
                final updated = user?.preferences.copyWith(bedtimeReminderEnabled: v);
                if (updated != null) {
                  await ref.read(bedtimeReminderProvider).syncFromPreferences(updated);
                }
              },
            ),
            ListTile(
              title: const Text('Typical bedtime'),
              trailing: TextButton(
                onPressed: () => _pickBedtime(context, ref, user),
                child: Text(
                  _formatTime(
                    user?.preferences.typicalBedtimeHour ?? 23,
                    user?.preferences.typicalBedtimeMinute ?? 0,
                  ),
                ),
              ),
            ),
            SwitchListTile(
              title: const Text('Wind-Down Mode'),
              subtitle: const Text('Dim UI 30 min before bedtime'),
              value: user?.preferences.windDownEnabled ?? false,
              onChanged: (v) async {
                await _updatePrefs(ref, user, windDownEnabled: v);
                final updated = user?.preferences.copyWith(windDownEnabled: v);
                if (updated != null) {
                  await ref.read(bedtimeReminderProvider).syncFromPreferences(updated);
                }
              },
            ),
            SwitchListTile(
              title: const Text('Travel Mode'),
              value: user?.preferences.travelModeEnabled ?? false,
              onChanged: (v) async {
                if (v && user?.isPremium != true) {
                  context.push('/premium');
                  return;
                }
                _updatePrefs(ref, user, travelModeEnabled: v);
                if (v) {
                  await ref.read(travelModeProvider).enable();
                } else {
                  await ref.read(travelModeProvider).disable();
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.notifications_active),
              title: const Text('Test Alarm (1 min)'),
              subtitle: const Text('Verify notifications are working'),
              onTap: () async {
                await ref.read(alarmSchedulerProvider).scheduleTestAlarm();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Test alarm scheduled in 1 minute')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.battery_alert_outlined),
              title: const Text('Battery Optimization'),
              subtitle: const Text('Disable battery restrictions for reliable alarms'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Go to Settings → Apps → SmartWake → Battery → Unrestricted',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events_outlined),
              title: const Text('Challenge Streak'),
              subtitle: Text(
                '${ref.watch(challengeStatsStateProvider).firstTryStreak} day streak '
                '(best: ${ref.watch(challengeStatsStateProvider).bestStreak})',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Registered barcode'),
              subtitle: Text(
                user?.preferences.registeredBarcode ?? 'Not set — tap to scan',
              ),
              onTap: () => context.push('/settings/register-barcode'),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_2),
              title: const Text('Registered QR code'),
              subtitle: Text(
                user?.preferences.registeredQrCode ?? 'Not set — tap to scan',
              ),
              onTap: () => context.push('/settings/register-qr'),
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome_outlined),
              title: const Text('How Smart Wake works'),
              onTap: () => showSmartWakeExplainer(context),
            ),
            ListTile(
              leading: const Icon(Icons.new_releases_outlined),
              title: const Text('What\'s new'),
              subtitle: const Text('v1.0.0 — Smart Wake, challenges, Premium'),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: AppConstants.appName,
                applicationVersion: '1.0.0',
                children: const [
                  Text(
                    '• Alarm armed status & confidence badges\n'
                    '• 7-day calibration week\n'
                    '• Bedtime reminders & wind-down mode\n'
                    '• Challenge difficulty & streak stats\n'
                    '• Lifetime Premium option',
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Sleep Stage Disclaimer'),
              subtitle: Text(
                AppConstants.sleepStageDisclaimer,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('Restore Purchases'),
              onTap: () =>
                  ref.read(subscriptionServiceProvider).restorePurchases(),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy Policy'),
              onTap: () => _openUrl(AppConstants.privacyPolicyUrl),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Terms of Service'),
              onTap: () => _openUrl(AppConstants.termsOfServiceUrl),
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Support'),
              onTap: () => _openUrl(AppConstants.supportUrl),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () => ref.read(userRepositoryProvider).signOut(),
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                '${AppConstants.appName} v1.0.0',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _updatePrefs(
    WidgetRef ref,
    UserProfile? user, {
    bool? darkMode,
    bool? use24HourFormat,
    bool? hapticFeedback,
    bool? reduceMotion,
    bool? largeText,
    bool? healthSyncEnabled,
    bool? cloudSyncEnabled,
    bool? notificationsEnabled,
    bool? easyChallengeMode,
    bool? bedtimeReminderEnabled,
    bool? windDownEnabled,
    bool? travelModeEnabled,
  }) async {
    if (user == null) return;
    await ref.read(userRepositoryProvider).saveUser(
          user.copyWith(
            preferences: user.preferences.copyWith(
              darkMode: darkMode,
              use24HourFormat: use24HourFormat,
              hapticFeedback: hapticFeedback,
              reduceMotion: reduceMotion,
              largeText: largeText,
              healthSyncEnabled: healthSyncEnabled,
              cloudSyncEnabled: cloudSyncEnabled,
              notificationsEnabled: notificationsEnabled,
              easyChallengeMode: easyChallengeMode,
              bedtimeReminderEnabled: bedtimeReminderEnabled,
              windDownEnabled: windDownEnabled,
              travelModeEnabled: travelModeEnabled,
            ),
          ),
        );
  }

  Future<void> _pickBedtime(
    BuildContext context,
    WidgetRef ref,
    UserProfile? user,
  ) async {
    if (user == null) return;
    final initial = TimeOfDay(
      hour: user.preferences.typicalBedtimeHour,
      minute: user.preferences.typicalBedtimeMinute,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    final updated = user.copyWith(
      preferences: user.preferences.copyWith(
        typicalBedtimeHour: picked.hour,
        typicalBedtimeMinute: picked.minute,
      ),
    );
    await ref.read(userRepositoryProvider).saveUser(updated);
    await ref.read(bedtimeReminderProvider).syncFromPreferences(updated.preferences);
  }

  String _formatTime(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
