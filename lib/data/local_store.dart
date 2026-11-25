import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Tiny JSON store on top of SharedPreferences: each collection is one key
/// holding a JSON list. It's the only class that touches device storage, so
/// Phase 5 replaces this layer (and the Local* services) with the database.
class LocalStore {
  LocalStore(this._prefs);
  final SharedPreferences _prefs;

  static Future<LocalStore> open() async => LocalStore(await SharedPreferences.getInstance());

  List<Map<String, dynamic>> readList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    return [for (final e in jsonDecode(raw) as List) Map<String, dynamic>.from(e as Map)];
  }

  Future<void> writeList(String key, List<Map<String, dynamic>> items) => _prefs.setString(key, jsonEncode(items));

  String? readString(String key) => _prefs.getString(key);
  Future<void> writeString(String key, String? value) => value == null ? _prefs.remove(key) : _prefs.setString(key, value);

  bool readBool(String key) => _prefs.getBool(key) ?? false;
  Future<void> writeBool(String key, bool value) => _prefs.setBool(key, value);

  Future<void> clear() => _prefs.clear();
}

/// Keys, in one place.
abstract final class StoreKeys {
  static const users = 'users';
  static const providers = 'providers';
  static const requests = 'requests';
  static const reviews = 'reviews';
  static const favorites = 'favorites'; // list of {userId, providerId}
  static const session = 'session_user_id';
  static const seeded = 'seeded_v1';
  static const onboarded = 'onboarded';
}
