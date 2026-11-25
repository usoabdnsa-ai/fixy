import '../data/models.dart';
import 'auth_service.dart';
import 'provider_service.dart';
import 'request_service.dart';
import 'review_service.dart';

/// Platform numbers for the admin dashboard.
class PlatformStats {
  PlatformStats({
    required this.clients,
    required this.providers,
    required this.verified,
    required this.toVerify,
    required this.suspended,
    required this.byStatus,
    required this.byCategory,
    required this.reviews,
    required this.averageRating,
    required this.toModerate,
    required this.last7Days,
  });

  final int clients, providers, verified, toVerify, suspended;
  final Map<RequestStatus, int> byStatus;
  final Map<Category, int> byCategory;
  final int reviews;
  final double averageRating;
  final int toModerate;

  /// Requests created on each of the last 7 days, oldest first.
  final List<int> last7Days;

  int get requests => byStatus.values.fold(0, (a, b) => a + b);

  /// Share of closed requests that were completed rather than cancelled.
  double get completionRate {
    final closed = (byStatus[RequestStatus.terminee] ?? 0) + (byStatus[RequestStatus.annulee] ?? 0);
    return closed == 0 ? 0 : (byStatus[RequestStatus.terminee] ?? 0) / closed;
  }
}

/// What the Fixy team can do: verify or suspend providers and moderate reviews.
/// Every action checks that the signed-in account really is an admin.
class AdminService {
  AdminService(this._auth, this._providers, this._requests, this._reviews);

  final AuthService _auth;
  final ProviderService _providers;
  final RequestService _requests;
  final ReviewService _reviews;

  /// A review at or below this many stars goes to the moderation queue.
  static const lowStars = 2;

  void _check() {
    if (_auth.currentUser?.role != Role.admin) throw FixyException('Action réservée aux administrateurs.');
  }

  Provider _provider(String id) => _providers.byId(id) ?? (throw FixyException('Prestataire introuvable.'));

  /// Providers waiting for the badge: not verified and not suspended.
  List<Provider> get toVerify => _providers.all.where((p) => !p.verified && !p.suspended).toList();

  /// Low-rated reviews no admin has looked at yet.
  List<Review> get toModerate => _reviews.all.where((r) => !r.moderated && r.stars <= lowStars).toList();

  Future<void> setVerified(String providerId, bool verified) async {
    _check();
    final p = _provider(providerId);
    p.verified = verified;
    if (verified) p.suspended = false;
    await _providers.save(p);
  }

  Future<void> setSuspended(String providerId, bool suspended) async {
    _check();
    final p = _provider(providerId);
    p.suspended = suspended;
    await _providers.save(p);
  }

  /// Keep ([hidden] false) or hide a review. Either way it leaves the queue.
  Future<void> moderateReview(String reviewId, {required bool hidden}) async {
    _check();
    await _reviews.moderate(reviewId, hidden: hidden);
  }

  PlatformStats stats(DateTime now) {
    final providers = _providers.all;
    final reqs = _requests.all;
    final visible = _reviews.all.where((r) => !r.hidden).toList();
    final today = DateTime(now.year, now.month, now.day);
    return PlatformStats(
      clients: _auth.all.where((u) => u.role == Role.client).length,
      providers: providers.length,
      verified: providers.where((p) => p.verified && !p.suspended).length,
      toVerify: toVerify.length,
      suspended: providers.where((p) => p.suspended).length,
      byStatus: {for (final s in RequestStatus.values) s: reqs.where((r) => r.status == s).length},
      byCategory: {for (final c in Category.values) c: reqs.where((r) => _providers.byId(r.providerId)?.category == c).length},
      reviews: visible.length,
      averageRating: visible.isEmpty ? 0 : visible.map((r) => r.stars).reduce((a, b) => a + b) / visible.length,
      toModerate: toModerate.length,
      last7Days: [
        for (var d = 6; d >= 0; d--)
          reqs.where((r) {
            final day = today.subtract(Duration(days: d));
            return !r.createdAt.isBefore(day) && r.createdAt.isBefore(day.add(const Duration(days: 1)));
          }).length,
      ],
    );
  }
}
