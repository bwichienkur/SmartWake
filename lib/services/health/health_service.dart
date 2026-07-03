import 'dart:io';

import 'package:health/health.dart';

import '../../domain/entities/sleep_stage.dart';
import '../../domain/repositories/repositories.dart';
import '../sensors/phone_sensor_service.dart';

/// Integrates Apple HealthKit / Health Connect with phone sensor fallback.
class HealthService implements HealthRepository {
  HealthService(this._phoneSensors);

  final PhoneSensorService _phoneSensors;
  final Health _health = Health();
  bool _configured = false;
  bool _permissionsGranted = false;
  bool _wearableConnected = false;

  static const _readTypes = [
    HealthDataType.HEART_RATE,
    HealthDataType.HEART_RATE_VARIABILITY_SDNN,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    HealthDataType.STEPS,
  ];

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  @override
  Future<bool> requestPermissions() async {
    try {
      if (!Platform.isIOS && !Platform.isAndroid) {
        _phoneSensors.startMonitoring();
        return false;
      }

      await _ensureConfigured();

      if (Platform.isAndroid) {
        final available = await _health.isHealthConnectAvailable();
        if (!available) {
          _phoneSensors.startMonitoring();
          return false;
        }
      }

      final granted = await _health.requestAuthorization(_readTypes);
      _permissionsGranted = granted;
      _wearableConnected = granted && await _detectWearableData();
      if (!_wearableConnected) {
        _phoneSensors.startMonitoring();
      }
      return granted;
    } catch (_) {
      _phoneSensors.startMonitoring();
      return false;
    }
  }

  Future<bool> _detectWearableData() async {
    try {
      final now = DateTime.now();
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: now.subtract(const Duration(hours: 12)),
        endTime: now,
      );
      return data.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isWearableConnected() async {
    if (!_permissionsGranted) return false;
    return _wearableConnected;
  }

  @override
  Future<SensorSource> getActiveSensorSource() async {
    if (_wearableConnected) {
      return Platform.isIOS
          ? SensorSource.appleWatch
          : SensorSource.healthConnect;
    }
    return SensorSource.phoneAccelerometer;
  }

  @override
  Future<double?> getHeartRate() async {
    if (!_permissionsGranted) return null;
    try {
      final now = DateTime.now();
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: now.subtract(const Duration(minutes: 30)),
        endTime: now,
      );
      if (data.isEmpty) return null;
      data.sort((a, b) => b.dateTo.compareTo(a.dateTo));
      final value = data.first.value;
      if (value is NumericHealthValue) {
        return value.numericValue.toDouble();
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<double?> getHrv() async {
    if (!_permissionsGranted) return null;
    try {
      final now = DateTime.now();
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE_VARIABILITY_SDNN],
        startTime: now.subtract(const Duration(hours: 8)),
        endTime: now,
      );
      if (data.isEmpty) return null;
      data.sort((a, b) => b.dateTo.compareTo(a.dateTo));
      final value = data.first.value;
      if (value is NumericHealthValue) {
        return value.numericValue.toDouble();
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<double> getMovementScore() async {
    return _phoneSensors.movementScore;
  }
}
