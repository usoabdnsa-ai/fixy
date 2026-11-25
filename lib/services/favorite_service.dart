import '../data/local_store.dart';

abstract class FavoriteService {
  Set<String> idsFor(String userId);
  Future<bool> toggle(String userId, String providerId);
}

class LocalFavoriteService implements FavoriteService {
  LocalFavoriteService(this._store) {
    for (final j in _store.readList(StoreKeys.favorites)) {
      _byUser.putIfAbsent(j['userId'] as String, () => <String>{}).add(j['providerId'] as String);
    }
  }

  final LocalStore _store;
  final _byUser = <String, Set<String>>{};

  @override
  Set<String> idsFor(String userId) => Set.unmodifiable(_byUser[userId] ?? const <String>{});

  /// Returns true if the provider is now a favourite.
  @override
  Future<bool> toggle(String userId, String providerId) async {
    final set = _byUser.putIfAbsent(userId, () => <String>{});
    final added = set.add(providerId);
    if (!added) set.remove(providerId);
    await _store.writeList(StoreKeys.favorites, [
      for (final e in _byUser.entries)
        for (final p in e.value) {'userId': e.key, 'providerId': p},
    ]);
    return added;
  }
}
