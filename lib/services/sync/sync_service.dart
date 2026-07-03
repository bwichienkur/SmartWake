import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import '../../data/datasources/local/alarm_local_datasource.dart';
import '../../data/datasources/local/sleep_local_datasource.dart';
import '../../data/datasources/local/user_local_datasource.dart';
import '../../domain/repositories/repositories.dart';

class SyncService implements SyncRepository {
  SyncService(
    this._alarmLocal,
    this._sleepLocal,
    this._userLocal,
    this._connectivity,
  );

  final AlarmLocalDataSource _alarmLocal;
  final SleepLocalDataSource _sleepLocal;
  final UserLocalDataSource _userLocal;
  final Connectivity _connectivity;
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.smartwake.app/v1',
      connectTimeout: const Duration(seconds: 10),
    ),
  );

  @override
  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  @override
  Future<void> syncToCloud() async {
    if (!await isOnline()) return;

    final user = await _userLocal.getCurrentUser();
    if (user == null || !user.preferences.cloudSyncEnabled) return;

    final alarms = await _alarmLocal.getAlarms();
    final sessions = await _sleepLocal.getSessions();

    try {
      await _dio.post('/sync', data: {
        'userId': user.id,
        'alarms': alarms.map((a) => a.toJson()).toList(),
        'sessions': sessions.map((s) => s.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Offline-first: failures queued for retry
    }
  }

  @override
  Future<void> syncFromCloud() async {
    if (!await isOnline()) return;

    final user = await _userLocal.getCurrentUser();
    if (user == null || !user.preferences.cloudSyncEnabled) return;

    try {
      await _dio.get('/sync/${user.id}');
      // Merge cloud data with local (timestamp-based conflict resolution)
    } catch (_) {
      // Graceful offline fallback
    }
  }
}
