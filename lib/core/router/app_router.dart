import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/screens/alarm/alarm_editor_screen.dart';
import '../../presentation/screens/alarm/alarm_ring_screen.dart';
import '../../presentation/screens/alarm/alarms_screen.dart';
import '../../presentation/screens/home/home_shell.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/settings/barcode_registration_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/sleep/sleep_dashboard_screen.dart';
import '../../presentation/screens/sleep/sleep_detail_screen.dart';
import '../../presentation/screens/subscription/premium_screen.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter create({required bool onboardingComplete}) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: onboardingComplete ? '/' : '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (_, __) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/alarm-ring',
          builder: (_, __) => const AlarmRingScreen(),
        ),
        GoRoute(
          path: '/alarm/new',
          builder: (_, __) => const AlarmEditorScreen(),
        ),
        GoRoute(
          path: '/alarm/:id/edit',
          builder: (context, state) => AlarmEditorScreen(
            alarmId: state.pathParameters['id'],
          ),
        ),
        GoRoute(
          path: '/premium',
          builder: (_, __) => const PremiumScreen(),
        ),
        GoRoute(
          path: '/settings/register-barcode',
          builder: (_, __) =>
              const BarcodeRegistrationScreen(mode: BarcodeScanMode.barcode),
        ),
        GoRoute(
          path: '/settings/register-qr',
          builder: (_, __) =>
              const BarcodeRegistrationScreen(mode: BarcodeScanMode.qr),
        ),
        GoRoute(
          path: '/sleep/:id',
          builder: (context, state) => SleepDetailScreen(
            sessionId: state.pathParameters['id']!,
          ),
        ),
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (_, __, child) => HomeShell(child: child),
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (_, __) => const NoTransitionPage(
                child: AlarmsScreen(),
              ),
            ),
            GoRoute(
              path: '/sleep',
              pageBuilder: (_, __) => const NoTransitionPage(
                child: SleepDashboardScreen(),
              ),
            ),
            GoRoute(
              path: '/settings',
              pageBuilder: (_, __) => const NoTransitionPage(
                child: SettingsScreen(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
