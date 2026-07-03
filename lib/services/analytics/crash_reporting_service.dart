import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Crash reporting — logs locally; wire Sentry via --dart-define=SENTRY_DSN=...
class CrashReportingService {
  CrashReportingService();

  final _log = Logger();
  static const _sentryDsn = String.fromEnvironment('SENTRY_DSN');

  Future<void> init() async {
    FlutterError.onError = (details) {
      recordError(
        details.exception,
        details.stack,
        reason: 'FlutterError',
      );
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      recordError(error, stack, reason: 'PlatformDispatcher');
      return true;
    };

    if (_sentryDsn.isNotEmpty) {
      _log.i('Sentry DSN configured — add sentry_flutter package to enable');
    }
  }

  void recordError(Object error, StackTrace? stack, {String? reason}) {
    _log.e(reason ?? 'error', error: error, stackTrace: stack);
    // When ready: Sentry.captureException(error, stackTrace: stack);
  }

  Future<T> runGuarded<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e, st) {
      recordError(e, st, reason: 'runGuarded');
      rethrow;
    }
  }
}

Future<void> runAppGuarded(Future<void> Function() body) {
  return runZonedGuarded(
    () async {
      await body();
    },
    (error, stack) {
      debugPrint('Uncaught error: $error\n$stack');
    },
  )!;
}
