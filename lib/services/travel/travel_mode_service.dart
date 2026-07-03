import '../../data/datasources/local/local_storage_service.dart';

class TravelModeService {
  TravelModeService(this._storage);

  static const _key = 'travel_mode';

  final LocalStorageService _storage;

  bool get isEnabled => _storage.get(_key)?['enabled'] as bool? ?? false;

  String? get timezoneOffset =>
      _storage.get(_key)?['timezoneOffset'] as String?;

  Future<void> enable({String? timezoneOffset}) async {
    await _storage.put(_key, {
      'enabled': true,
      'timezoneOffset': timezoneOffset,
      'enabledAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> disable() async {
    await _storage.delete(_key);
  }

  /// Adjust wake times by offset hours when travel mode active.
  DateTime adjustWakeTime(DateTime time) {
    if (!isEnabled || timezoneOffset == null) return time;
    final offset = int.tryParse(timezoneOffset!) ?? 0;
    return time.add(Duration(hours: offset));
  }
}
