import '../../../domain/entities/user_profile.dart';
import 'local_storage_service.dart';

class UserLocalDataSource {
  UserLocalDataSource(this._storage);

  static const _userKey = 'current_user';

  final LocalStorageService _storage;

  Future<UserProfile?> getCurrentUser() async {
    final data = _storage.get(_userKey);
    if (data == null) return null;
    return UserProfile.fromJson(data);
  }

  Future<void> saveUser(UserProfile user) async {
    await _storage.put(_userKey, user.toJson());
  }

  Future<void> clearUser() async {
    await _storage.delete(_userKey);
  }
}
