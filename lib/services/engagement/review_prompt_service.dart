import '../../data/datasources/local/local_storage_service.dart';

class ReviewPromptService {
  ReviewPromptService(this._storage);

  static const _wakeCountKey = 'successful_wake_count';
  static const _promptedKey = 'review_prompted';
  static const minWakesBeforePrompt = 5;

  final LocalStorageService _storage;

  int get successfulWakeCount {
    final data = _storage.get(_wakeCountKey);
    return data?['count'] as int? ?? 0;
  }

  bool get hasBeenPrompted {
    final data = _storage.get(_promptedKey);
    return data?['prompted'] as bool? ?? false;
  }

  Future<void> recordSuccessfulWake() async {
    await _storage.put(_wakeCountKey, {'count': successfulWakeCount + 1});
  }

  bool shouldShowPrompt() =>
      !hasBeenPrompted && successfulWakeCount >= minWakesBeforePrompt;

  Future<void> markPrompted() async {
    await _storage.put(_promptedKey, {'prompted': true});
  }
}
