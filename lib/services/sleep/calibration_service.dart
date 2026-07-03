import '../../data/datasources/local/local_storage_service.dart';

class CalibrationService {
  CalibrationService(this._storage);

  static const _startKey = 'calibration_start';
  static const calibrationDays = 7;

  final LocalStorageService _storage;

  bool get isCalibrating {
    final start = calibrationStart;
    if (start == null) return false;
    return DateTime.now().difference(start).inDays < calibrationDays;
  }

  int get daysRemaining {
    if (!isCalibrating) return 0;
    final elapsed = DateTime.now().difference(calibrationStart!).inDays;
    return (calibrationDays - elapsed).clamp(0, calibrationDays);
  }

  DateTime? get calibrationStart {
    final raw = _storage.get(_startKey);
    if (raw == null) return null;
    return DateTime.parse(raw['date'] as String);
  }

  Future<void> startCalibration() async {
    await _storage.put(_startKey, {'date': DateTime.now().toIso8601String()});
  }

  Future<void> completeCalibration() async {
    await _storage.delete(_startKey);
  }
}
