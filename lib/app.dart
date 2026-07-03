import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/di/providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'domain/entities/user_profile.dart';
import 'domain/entities/alarm.dart';
import 'presentation/widgets/review_prompt_dialog.dart';
import 'presentation/widgets/wind_down_overlay.dart';
import 'services/alarm/alarm_engine.dart';

class SmartWakeApp extends ConsumerStatefulWidget {
  const SmartWakeApp({super.key});

  @override
  ConsumerState<SmartWakeApp> createState() => _SmartWakeAppState();
}

class _SmartWakeAppState extends ConsumerState<SmartWakeApp> {
  GoRouter? _router;
  bool _reviewPromptShownThisSession = false;

  @override
  void initState() {
    super.initState();
    _initRouter();
  }

  Future<void> _initRouter() async {
    final user = await ref.read(userRepositoryProvider).getCurrentUser();
    setState(() {
      _router = AppRouter.create(
        onboardingComplete: user?.preferences.onboardingCompleted ?? false,
      );
    });
  }

  Future<void> _maybeShowReviewPrompt() async {
    if (_reviewPromptShownThisSession) return;
    final review = ref.read(reviewPromptProvider);
    if (!review.shouldShowPrompt()) return;
    _reviewPromptShownThisSession = true;
    await review.markPrompted();
    if (!mounted || _router == null) return;
    final ctx = _router!.routerDelegate.navigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      await showReviewPromptDialog(ctx);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_router == null) {
      return MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    ref.listen<AlarmEngine>(alarmEngineProvider, (prev, next) {
      if (next.ringState == AlarmRingState.ringing ||
          next.ringState == AlarmRingState.countdown ||
          next.ringState == AlarmRingState.challengeActive) {
        _router?.go('/alarm-ring');
      }
      if (prev?.ringState != AlarmRingState.dismissed &&
          next.ringState == AlarmRingState.dismissed) {
        _maybeShowReviewPrompt();
      }
    });

    final userAsync = ref.watch(userProvider);
    final isDark = userAsync.maybeWhen(
      data: (user) => user?.preferences.darkMode ?? true,
      orElse: () => true,
    );
    final showWindDown = userAsync.maybeWhen(
      data: (user) => _isWindDownActive(user?.preferences),
      orElse: () => false,
    );

    return MaterialApp.router(
      title: 'SmartWake',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: _router,
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            if (showWindDown) const WindDownOverlay(),
          ],
        );
      },
    );
  }

  bool _isWindDownActive(UserPreferences? prefs) {
    if (prefs == null || !prefs.windDownEnabled) return false;
    final now = DateTime.now();
    final bedtime = DateTime(
      now.year,
      now.month,
      now.day,
      prefs.typicalBedtimeHour,
      prefs.typicalBedtimeMinute,
    );
    final windDownStart = bedtime.subtract(const Duration(minutes: 30));
    return now.isAfter(windDownStart) && now.isBefore(bedtime);
  }
}
