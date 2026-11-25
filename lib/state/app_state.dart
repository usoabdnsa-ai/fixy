import 'package:flutter/foundation.dart';

import '../data/local_store.dart';
import '../data/models.dart';
import '../data/seed.dart';
import '../services/auth_service.dart';
import '../services/favorite_service.dart';
import '../services/provider_service.dart';
import '../services/request_service.dart';
import '../services/review_service.dart';

/// The one object screens talk to. It forwards to the services and tells
/// the UI to rebuild after every change. Screens never touch storage directly.
class AppState extends ChangeNotifier {
  AppState._(this._store, this.auth, this.providers, this.requests, this.reviews, this.favorites);

  final LocalStore _store;
  final AuthService auth;
  final ProviderService providers;
  final RequestService requests;
  final ReviewService reviews;
  final FavoriteService favorites;

  static Future<AppState> load() async {
    final store = await LocalStore.open();
    final auth = LocalAuthService(store);
    final providers = LocalProviderService(store);
    final requests = LocalRequestService(store);
    final reviews = LocalReviewService(store);
    if (!store.readBool(StoreKeys.seeded)) {
      final seed = buildSeed(DateTime.now());
      await auth.addAll(seed.users);
      await providers.addAll(seed.providers);
      await reviews.addAll(seed.reviews);
      await requests.addAll(seed.requests);
      await store.writeBool(StoreKeys.seeded, true);
    }
    return AppState._(store, auth, providers, requests, reviews, LocalFavoriteService(store));
  }

  // ---------- session ----------
  AppUser? get user => auth.currentUser;
  bool get onboarded => _store.readBool(StoreKeys.onboarded);
  Future<void> finishOnboarding() => _store.writeBool(StoreKeys.onboarded, true);

  /// The signed-in provider's profile, if the user is a prestataire with a profile.
  Provider? get myProvider => user == null ? null : providers.byId(user!.id);

  Future<T> _run<T>(Future<T> Function() f) async {
    final r = await f();
    notifyListeners();
    return r;
  }

  Future<AppUser> register({required String name, required String phone, String? email, required String password}) =>
      _run(() => auth.register(name: name, phone: phone, email: email, password: password));
  Future<AppUser> login(String identifier, String password) => _run(() => auth.login(identifier: identifier, password: password));
  Future<void> chooseRole(Role r) => _run(() => auth.chooseRole(r));
  Future<void> updateUser(AppUser u) => _run(() => auth.update(u));
  Future<void> logout() => _run(() {
    _location = null;
    return auth.logout();
  });

  // ---------- current location (home screen pill) ----------
  SavedAddress? _location;

  /// The address searches start from: the one picked on the home screen, else the first saved address.
  SavedAddress? get location => _location ?? ((user?.addresses.isNotEmpty ?? false) ? user!.addresses.first : null);
  void setLocation(SavedAddress a) {
    _location = a;
    notifyListeners();
  }

  // ---------- providers ----------
  RatingSummary rating(String providerId) => reviews.summary(providerId);
  List<Provider> search(ProviderQuery q) => providers.search(q, (id) => rating(id).average);
  List<Provider> popular({int limit = 6}) =>
      providers.search(const ProviderQuery(sort: SortBy.recommended), (id) => rating(id).average).where((p) => rating(p.id).count >= 3).take(limit).toList();
  Future<void> saveProvider(Provider p) => _run(() => providers.save(p));

  // ---------- favourites ----------
  bool isFavorite(String providerId) => user != null && favorites.idsFor(user!.id).contains(providerId);
  List<Provider> get favoriteProviders =>
      user == null ? [] : [for (final id in favorites.idsFor(user!.id)) ?providers.byId(id)];
  Future<bool> toggleFavorite(String providerId) => _run(() => favorites.toggle(user!.id, providerId));

  // ---------- requests ----------
  List<ServiceRequest> get myRequests => user == null ? [] : requests.forClient(user!.id);
  List<ServiceRequest> get incoming => user == null ? [] : requests.forProvider(user!.id);
  int incomingCount(RequestStatus s) => incoming.where((r) => r.status == s).length;

  /// Requests from the last 24 h still waiting: the "Nouvelles demandes" counter.
  int get newIncoming =>
      incoming.where((r) => r.status == RequestStatus.enAttente && DateTime.now().difference(r.createdAt) < const Duration(hours: 24)).length;

  Future<ServiceRequest> createRequest({
    required Provider provider,
    required String service,
    required String description,
    required String address,
    required DateTime scheduledAt,
    String? photo,
  }) => _run(
    () => requests.create(client: user!, provider: provider, service: service, description: description, address: address, scheduledAt: scheduledAt, photo: photo),
  );

  Future<void> accept(String id) => _run(() => requests.accept(id, providerId: user!.id));
  Future<void> refuse(String id) => _run(() => requests.refuse(id, providerId: user!.id));
  Future<void> finish(String id) => _run(() => requests.finish(id, providerId: user!.id));
  Future<void> cancel(String id) => _run(() => requests.cancel(id, clientId: user!.id));

  Future<void> addReview(ServiceRequest r, int stars, String comment) => _run(() async {
    await reviews.add(request: r, author: user!, stars: stars, comment: comment);
    await requests.markReviewed(r.id);
  });
}
