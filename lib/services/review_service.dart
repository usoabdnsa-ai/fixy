import '../data/local_store.dart';
import '../data/models.dart';
import 'auth_service.dart';

abstract class ReviewService {
  List<Review> forProvider(String providerId);
  RatingSummary summary(String providerId);
  Future<Review> add({required ServiceRequest request, required AppUser author, required int stars, required String comment});
}

class LocalReviewService implements ReviewService {
  LocalReviewService(this._store) {
    _items = [for (final j in _store.readList(StoreKeys.reviews)) Review.fromJson(j)];
  }

  final LocalStore _store;
  late List<Review> _items;
  final _cache = <String, RatingSummary>{};

  @override
  List<Review> forProvider(String providerId) =>
      _items.where((r) => r.providerId == providerId).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  RatingSummary summary(String providerId) => _cache.putIfAbsent(providerId, () => RatingSummary(forProvider(providerId)));

  /// One review per completed request, written by the client who made it.
  @override
  Future<Review> add({required ServiceRequest request, required AppUser author, required int stars, required String comment}) async {
    if (request.clientId != author.id) throw FixyException("Seul le client de cette demande peut l'évaluer.");
    if (request.status != RequestStatus.terminee) throw FixyException('Vous pourrez évaluer une fois le service terminé.');
    if (request.reviewed || _items.any((r) => r.requestId == request.id)) throw FixyException('Vous avez déjà évalué ce service.');
    if (stars < 1 || stars > 5) throw FixyException('Choisissez une note de 1 à 5 étoiles.');
    final r = Review(
      id: 'v${DateTime.now().microsecondsSinceEpoch}',
      providerId: request.providerId,
      requestId: request.id,
      authorId: author.id,
      authorName: author.name,
      stars: stars,
      comment: comment.trim(),
      createdAt: DateTime.now(),
    );
    _items.add(r);
    _cache.remove(request.providerId);
    await _store.writeList(StoreKeys.reviews, _items.map((x) => x.toJson()).toList());
    return r;
  }

  Future<void> addAll(List<Review> rs) async {
    _items.addAll(rs);
    _cache.clear();
    await _store.writeList(StoreKeys.reviews, _items.map((x) => x.toJson()).toList());
  }
}
