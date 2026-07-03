import '../../../domain/entities/sleep_session.dart';
import 'local_storage_service.dart';

class SleepLocalDataSource {
  SleepLocalDataSource(this._storage);

  static const _sessionsKey = 'sleep_sessions';

  final LocalStorageService _storage;

  Future<List<SleepSession>> getSessions({DateTime? from, DateTime? to}) async {
    final data = _storage.getList(_sessionsKey);
    var sessions = data.map(SleepSession.fromJson).toList();
    if (from != null) {
      sessions = sessions.where((s) => s.wakeTime.isAfter(from)).toList();
    }
    if (to != null) {
      sessions = sessions.where((s) => s.bedTime.isBefore(to)).toList();
    }
    sessions.sort((a, b) => b.bedTime.compareTo(a.bedTime));
    return sessions;
  }

  Future<SleepSession?> getSessionById(String id) async {
    final sessions = await getSessions();
    try {
      return sessions.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSession(SleepSession session) async {
    final sessions = await getSessions();
    final index = sessions.indexWhere((s) => s.id == session.id);
    if (index >= 0) {
      sessions[index] = session;
    } else {
      sessions.add(session);
    }
    await _storage.putList(
      _sessionsKey,
      sessions.map((s) => s.toJson()).toList(),
    );
  }

  Future<void> deleteSession(String id) async {
    final sessions = await getSessions();
    sessions.removeWhere((s) => s.id == id);
    await _storage.putList(
      _sessionsKey,
      sessions.map((s) => s.toJson()).toList(),
    );
  }
}
