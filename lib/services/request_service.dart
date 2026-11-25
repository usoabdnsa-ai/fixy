import '../data/local_store.dart';
import '../data/models.dart';
import 'auth_service.dart';

/// The 4-status life cycle of a service request:
///
///   En attente ──accept (provider)──▶ Acceptée ──finish (provider)──▶ Terminée
///        │                               │
///        ├──cancel (client)──────────────┴──cancel (client)──▶ Annulée
///        └──refuse (provider)─────────────────────────────────▶ Annulée
///
/// Terminée and Annulée are final.
abstract class RequestService {
  List<ServiceRequest> forClient(String clientId);
  List<ServiceRequest> forProvider(String providerId);
  ServiceRequest? byId(String id);
  Future<ServiceRequest> create({
    required AppUser client,
    required Provider provider,
    required String service,
    required String description,
    required String address,
    required DateTime scheduledAt,
    String? photo,
  });
  Future<void> accept(String id, {required String providerId});
  Future<void> refuse(String id, {required String providerId});
  Future<void> finish(String id, {required String providerId});
  Future<void> cancel(String id, {required String clientId});
  Future<void> markReviewed(String id);
}

class LocalRequestService implements RequestService {
  LocalRequestService(this._store) {
    _items = [for (final j in _store.readList(StoreKeys.requests)) ServiceRequest.fromJson(j)];
  }

  final LocalStore _store;
  late List<ServiceRequest> _items;

  Future<void> _save() => _store.writeList(StoreKeys.requests, _items.map((r) => r.toJson()).toList());

  List<ServiceRequest> _sorted(Iterable<ServiceRequest> rs) => rs.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  List<ServiceRequest> forClient(String clientId) => _sorted(_items.where((r) => r.clientId == clientId));

  @override
  List<ServiceRequest> forProvider(String providerId) => _sorted(_items.where((r) => r.providerId == providerId));

  @override
  ServiceRequest? byId(String id) {
    for (final r in _items) {
      if (r.id == id) return r;
    }
    return null;
  }

  @override
  Future<ServiceRequest> create({
    required AppUser client,
    required Provider provider,
    required String service,
    required String description,
    required String address,
    required DateTime scheduledAt,
    String? photo,
  }) async {
    if (client.id == provider.id) throw FixyException('Vous ne pouvez pas vous envoyer une demande.');
    if (description.trim().length < 10) throw FixyException('Décrivez le problème en quelques mots (10 caractères minimum).');
    if (address.trim().length < 5) throw FixyException("Indiquez l'adresse d'intervention.");
    if (scheduledAt.isBefore(DateTime.now().subtract(const Duration(minutes: 5)))) {
      throw FixyException('Choisissez une date et une heure à venir.');
    }
    final r = ServiceRequest(
      id: 'r${DateTime.now().microsecondsSinceEpoch}',
      clientId: client.id,
      clientName: client.name,
      clientPhone: client.phone,
      providerId: provider.id,
      service: service,
      description: description.trim(),
      address: address.trim(),
      scheduledAt: scheduledAt,
      createdAt: DateTime.now(),
      photo: photo,
    );
    _items.add(r);
    await _save();
    return r;
  }

  ServiceRequest _get(String id) => byId(id) ?? (throw FixyException('Demande introuvable.'));

  void _mustOwnAsProvider(ServiceRequest r, String providerId) {
    if (r.providerId != providerId) throw FixyException("Cette demande ne vous est pas adressée.");
  }

  @override
  Future<void> accept(String id, {required String providerId}) async {
    final r = _get(id);
    _mustOwnAsProvider(r, providerId);
    if (r.status != RequestStatus.enAttente) throw FixyException('Seule une demande en attente peut être acceptée.');
    r.status = RequestStatus.acceptee;
    await _save();
  }

  @override
  Future<void> refuse(String id, {required String providerId}) async {
    final r = _get(id);
    _mustOwnAsProvider(r, providerId);
    if (r.status != RequestStatus.enAttente) throw FixyException('Seule une demande en attente peut être refusée.');
    r.status = RequestStatus.annulee;
    r.cancelledBy = CancelledBy.prestataire;
    await _save();
  }

  @override
  Future<void> finish(String id, {required String providerId}) async {
    final r = _get(id);
    _mustOwnAsProvider(r, providerId);
    if (r.status != RequestStatus.acceptee) throw FixyException('Seule une demande acceptée peut être terminée.');
    r.status = RequestStatus.terminee;
    await _save();
  }

  @override
  Future<void> cancel(String id, {required String clientId}) async {
    final r = _get(id);
    if (r.clientId != clientId) throw FixyException("Cette demande n'est pas la vôtre.");
    if (r.status != RequestStatus.enAttente && r.status != RequestStatus.acceptee) {
      throw FixyException('Cette demande ne peut plus être annulée.');
    }
    r.status = RequestStatus.annulee;
    r.cancelledBy = CancelledBy.client;
    await _save();
  }

  @override
  Future<void> markReviewed(String id) async {
    _get(id).reviewed = true;
    await _save();
  }

  Future<void> addAll(List<ServiceRequest> rs) async {
    _items.addAll(rs);
    await _save();
  }
}
