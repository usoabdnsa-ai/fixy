import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../data/local_store.dart';
import '../data/models.dart';

/// Thrown by services with a message that can be shown to the user as is.
class FixyException implements Exception {
  FixyException(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class AuthService {
  AppUser? get currentUser;
  Future<AppUser> register({required String name, required String phone, String? email, required String password});
  Future<AppUser> login({required String identifier, required String password});
  Future<void> chooseRole(Role role);
  Future<void> update(AppUser user);
  Future<void> logout();
  AppUser? byId(String id);
}

/// Accounts stored on the device. Passwords are kept as SHA-256 hashes, never in clear.
/// (A real backend would use a slow salted hash such as bcrypt; that comes with Phase 5.)
class LocalAuthService implements AuthService {
  LocalAuthService(this._store) {
    _users = [for (final j in _store.readList(StoreKeys.users)) AppUser.fromJson(j)];
    final id = _store.readString(StoreKeys.session);
    _current = id == null ? null : byId(id);
  }

  final LocalStore _store;
  late List<AppUser> _users;
  AppUser? _current;

  static String hash(String password) => sha256.convert(utf8.encode('fixy:$password')).toString();

  /// "0550 12 34 56" and "+213550123456" both become "0550123456".
  static String normalizePhone(String raw) {
    var d = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (d.startsWith('+213')) d = '0${d.substring(4)}';
    if (d.startsWith('00213')) d = '0${d.substring(5)}';
    return d;
  }

  static bool validPhone(String raw) => RegExp(r'^0[5-7][0-9]{8}$').hasMatch(normalizePhone(raw));

  @override
  AppUser? get currentUser => _current;

  @override
  AppUser? byId(String id) {
    for (final u in _users) {
      if (u.id == id) return u;
    }
    return null;
  }

  Future<void> _save() => _store.writeList(StoreKeys.users, _users.map((u) => u.toJson()).toList());

  @override
  Future<AppUser> register({required String name, required String phone, String? email, required String password}) async {
    final p = normalizePhone(phone);
    if (name.trim().length < 3) throw FixyException('Entrez votre nom complet.');
    if (!validPhone(p)) throw FixyException('Numéro invalide. Exemple : 0550 12 34 56.');
    if (password.length < 6) throw FixyException('Le mot de passe doit contenir au moins 6 caractères.');
    final mail = (email ?? '').trim().toLowerCase();
    if (mail.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(mail)) throw FixyException('Adresse e-mail invalide.');
    if (_users.any((u) => u.phone == p)) throw FixyException('Un compte existe déjà avec ce numéro. Connectez-vous.');
    if (mail.isNotEmpty && _users.any((u) => u.email == mail)) throw FixyException('Un compte existe déjà avec cet e-mail.');
    final user = AppUser(
      id: 'u${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      phone: p,
      email: mail.isEmpty ? null : mail,
      passwordHash: hash(password),
      role: null,
    );
    _users.add(user);
    await _save();
    _current = user;
    await _store.writeString(StoreKeys.session, user.id);
    return user;
  }

  @override
  Future<AppUser> login({required String identifier, required String password}) async {
    final id = identifier.trim().toLowerCase();
    final phone = normalizePhone(id);
    AppUser? user;
    for (final u in _users) {
      if (u.phone == phone || (u.email != null && u.email == id)) user = u;
    }
    if (user == null || user.passwordHash != hash(password)) {
      throw FixyException('Numéro / e-mail ou mot de passe incorrect.');
    }
    _current = user;
    await _store.writeString(StoreKeys.session, user.id);
    return user;
  }

  @override
  Future<void> chooseRole(Role role) async {
    final u = _current;
    if (u == null) throw FixyException('Session expirée. Reconnectez-vous.');
    u.role = role;
    await _save();
  }

  @override
  Future<void> update(AppUser user) async {
    final p = normalizePhone(user.phone);
    if (!validPhone(p)) throw FixyException('Numéro invalide. Exemple : 0550 12 34 56.');
    if (_users.any((u) => u.id != user.id && u.phone == p)) throw FixyException('Ce numéro est déjà utilisé.');
    user.phone = p;
    await _save();
  }

  @override
  Future<void> logout() async {
    _current = null;
    await _store.writeString(StoreKeys.session, null);
  }

  /// Used by the seed to create demo accounts.
  Future<void> addAll(List<AppUser> users) async {
    _users.addAll(users);
    await _save();
  }
}
