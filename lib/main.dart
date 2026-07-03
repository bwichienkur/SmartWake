import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/di/providers.dart';
import 'core/utils/demo_data_seeder.dart';
import 'data/datasources/local/local_storage_service.dart';
import 'services/alarm/alarm_background.dart';
import 'services/alarm/alarm_scheduler_service.dart';
import 'services/alarm/notification_service.dart';
import 'services/analytics/crash_reporting_service.dart';

Future<void> main() async {
  await runAppGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    await initializeTimezones();

    final storage = LocalStorageService();
    await storage.init();

    final notifications = NotificationService();
    await notifications.init();

    await initAndroidAlarmBackground();

    final crashReporting = CrashReportingService();
    await crashReporting.init();

    runApp(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
        ],
        child: const _AppBootstrap(),
      ),
    );
  });
}

class _AppBootstrap extends ConsumerStatefulWidget {
  const _AppBootstrap();

  @override
  ConsumerState<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends ConsumerState<_AppBootstrap> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final seeder = DemoDataSeeder(
      ref.read(sleepRepositoryProvider),
      ref.read(sleepStageEstimatorProvider),
      ref.read(sleepAnalyticsProvider),
    );
    await seeder.seedIfEmpty();

    final calibration = ref.read(calibrationServiceProvider);
    if (calibration.calibrationStart == null) {
      await calibration.startCalibration();
    }

    await ref.read(alarmEngineProvider).bootstrap();

    final user = await ref.read(userRepositoryProvider).getCurrentUser();
    if (user != null) {
      await ref.read(bedtimeReminderProvider).syncFromPreferences(user.preferences);
    }
  }

  @override
  Widget build(BuildContext context) => const SmartWakeApp();
}
