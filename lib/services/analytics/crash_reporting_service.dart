import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Crash reporting scaffold — wire to Sentry/Crashlytics in production.
class CrashReportingService {
  CrashReportingService();

  final _log = Logger();

  Future<void> init() async {
    FlutterError.onError = (details) {
      _log.e('FlutterError', error: details.exception, stackTrace: details.stack);
    };
    // TODO: SentryFlutter.init / Firebase Crashlytics
  }

  void recordError(Object error, StackTrace? stack, {String? reason}) {
    _log.e(reason ?? 'error', error: error, stackTrace: stack);
  }
}
