import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

/// Phone sensor fallback when no wearable is connected.
class PhoneSensorService {
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  double _movementScore = 0;
  final _movementHistory = <double>[];

  double get movementScore => _movementScore;

  void startMonitoring() {
    _accelSub = accelerometerEventStream().listen(_onAccelerometer);
    _gyroSub = gyroscopeEventStream().listen(_onGyroscope);
  }

  void stopMonitoring() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
  }

  void _onAccelerometer(AccelerometerEvent event) {
    final magnitude = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );
    // Normalize: gravity ~9.8, movement adds variance
    final normalized = ((magnitude - 9.8).abs() / 5.0).clamp(0.0, 1.0);
    _movementHistory.add(normalized);
    if (_movementHistory.length > 60) {
      _movementHistory.removeAt(0);
    }
    _movementScore = _movementHistory.isEmpty
        ? 0
        : _movementHistory.reduce((a, b) => a + b) / _movementHistory.length;
  }

  void _onGyroscope(GyroscopeEvent event) {
    final rotation = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );
    final normalized = (rotation / 3.0).clamp(0.0, 1.0);
    _movementScore = (_movementScore * 0.7 + normalized * 0.3).clamp(0.0, 1.0);
  }

  void dispose() {
    stopMonitoring();
  }
}
