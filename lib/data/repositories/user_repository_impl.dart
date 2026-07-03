import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/repositories.dart';
import '../../data/datasources/local/user_local_datasource.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._local);

  final UserLocalDataSource _local;
  final _controller = StreamController<UserProfile?>.broadcast();
  static const _uuid = Uuid();

  @override
  Future<UserProfile?> getCurrentUser() async {
    var user = await _local.getCurrentUser();
    if (user == null) {
      user = UserProfile(
        id: _uuid.v4(),
        authProvider: AuthProvider.guest,
        createdAt: DateTime.now(),
      );
      await _local.saveUser(user);
    }
    return user;
  }

  @override
  Future<void> saveUser(UserProfile user) async {
    await _local.saveUser(user);
    _controller.add(user);
  }

  @override
  Stream<UserProfile?> watchUser() async* {
    yield await getCurrentUser();
    yield* _controller.stream;
  }

  @override
  Future<void> signOut() async {
    await _local.clearUser();
    _controller.add(null);
  }
}
