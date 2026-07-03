import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';

/// Encrypted offline-first local storage using Hive with secure key management.
class LocalStorageService {
  LocalStorageService({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;
  Box<String>? _box;

  Future<void> init() async {
    await Hive.initFlutter();
    final encryptionKey = await _getOrCreateEncryptionKey();
    _box = await Hive.openBox<String>(
      AppConstants.hiveBoxName,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
  }

  Future<List<int>> _getOrCreateEncryptionKey() async {
    final existing = await _secureStorage.read(key: AppConstants.secureStorageKey);
    if (existing != null) {
      return base64Decode(existing);
    }
    final key = Hive.generateSecureKey();
    await _secureStorage.write(
      key: AppConstants.secureStorageKey,
      value: base64Encode(key),
    );
    return key;
  }

  Future<void> put(String key, Map<String, dynamic> value) async {
    await _box?.put(key, jsonEncode(value));
  }

  Future<void> putList(String key, List<Map<String, dynamic>> values) async {
    await _box?.put(key, jsonEncode(values));
  }

  Map<String, dynamic>? get(String key) {
    final raw = _box?.get(key);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  List<Map<String, dynamic>> getList(String key) {
    final raw = _box?.get(key);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<void> delete(String key) async {
    await _box?.delete(key);
  }

  Future<void> clear() async {
    await _box?.clear();
  }

  ValueListenable<Box<String>> get listenable => _box!.listenable();
}
