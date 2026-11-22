import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DarbLocalCache {
  DarbLocalCache._();
  static final instance = DarbLocalCache._();

  static const _storage = FlutterSecureStorage();
  static const _prefix = 'darb_cache_v1_';

  Future<void> writeJson(String key, Object value) async {
    try {
      await _storage.write(key: '$_prefix$key', value: jsonEncode(value));
    } catch (_) {}
  }

  Future<dynamic> readJson(String key) async {
    try {
      final raw = await _storage.read(key: '$_prefix$key');
      if (raw == null || raw.isEmpty) return null;
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAll() async {
    try {
      final all = await _storage.readAll();
      for (final key in all.keys) {
        if (key.startsWith(_prefix)) {
          await _storage.delete(key: key);
        }
      }
    } catch (_) {}
  }
}
