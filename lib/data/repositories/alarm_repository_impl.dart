import 'dart:async';

import '../../../domain/entities/alarm.dart';
import '../../../domain/repositories/repositories.dart';
import '../datasources/local/alarm_local_datasource.dart';

class AlarmRepositoryImpl implements AlarmRepository {
  AlarmRepositoryImpl(this._local);

  final AlarmLocalDataSource _local;
  final _controller = StreamController<List<Alarm>>.broadcast();

  @override
  Future<List<Alarm>> getAlarms() => _local.getAlarms();

  @override
  Future<Alarm?> getAlarmById(String id) => _local.getAlarmById(id);

  @override
  Future<void> saveAlarm(Alarm alarm) async {
    await _local.saveAlarm(
      alarm.copyWith(updatedAt: DateTime.now()),
    );
    _emit();
  }

  @override
  Future<void> deleteAlarm(String id) async {
    await _local.deleteAlarm(id);
    _emit();
  }

  @override
  Stream<List<Alarm>> watchAlarms() async* {
    yield await getAlarms();
    yield* _controller.stream;
  }

  Future<void> _emit() async {
    _controller.add(await getAlarms());
  }
}
