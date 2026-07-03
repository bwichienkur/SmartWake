import '../../../domain/entities/alarm.dart';
import 'local_storage_service.dart';

class AlarmLocalDataSource {
  AlarmLocalDataSource(this._storage);

  static const _alarmsKey = 'alarms';

  final LocalStorageService _storage;

  Future<List<Alarm>> getAlarms() async {
    final data = _storage.getList(_alarmsKey);
    return data.map(Alarm.fromJson).toList();
  }

  Future<Alarm?> getAlarmById(String id) async {
    final alarms = await getAlarms();
    try {
      return alarms.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveAlarm(Alarm alarm) async {
    final alarms = await getAlarms();
    final index = alarms.indexWhere((a) => a.id == alarm.id);
    if (index >= 0) {
      alarms[index] = alarm;
    } else {
      alarms.add(alarm);
    }
    await _storage.putList(
      _alarmsKey,
      alarms.map((a) => a.toJson()).toList(),
    );
  }

  Future<void> deleteAlarm(String id) async {
    final alarms = await getAlarms();
    alarms.removeWhere((a) => a.id == id);
    await _storage.putList(
      _alarmsKey,
      alarms.map((a) => a.toJson()).toList(),
    );
  }
}
