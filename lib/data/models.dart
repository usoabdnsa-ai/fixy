import 'package:flutter/widgets.dart';

import '../widgets/icons.dart';

/// The 8 trades from the specification (section 4.2, F2).
enum Category {
  plombier('Plombier', 'Plomberie', PhosphorIconsBold.pipeWrench),
  electricien('Électricien', 'Électricité', PhosphorIconsBold.lightning),
  macon('Maçon', 'Maçonnerie', PhosphorIconsBold.wall),
  peintre('Peintre', 'Peinture', PhosphorIconsBold.paintRoller),
  nettoyeur('Nettoyeur', 'Nettoyage', PhosphorIconsBold.broom),
  menuisier('Menuisier', 'Menuiserie', PhosphorIconsBold.hammer),
  climatisation('Climatisation', 'Climatisation', PhosphorIconsBold.snowflake),
  serrurier('Serrurier', 'Serrurerie', PhosphorIconsBold.key);

  const Category(this.label, this.domain, this.icon);

  /// The person: "Plombier".
  final String label;

  /// The field: "Plomberie".
  final String domain;
  final IconData icon;

  static Category byName(String n) => Category.values.firstWhere((c) => c.name == n, orElse: () => Category.plombier);
}

/// [admin] accounts are created by the Fixy team only; nobody can pick it at sign-up.
enum Role { client, prestataire, admin }

/// The 4 request statuses from the specification.
enum RequestStatus {
  enAttente('En attente'),
  acceptee('Acceptée'),
  terminee('Terminée'),
  annulee('Annulée');

  const RequestStatus(this.label);
  final String label;

  static RequestStatus byName(String n) => RequestStatus.values.firstWhere((s) => s.name == n, orElse: () => RequestStatus.enAttente);
}

/// Who closed a request: the client (Annuler) or the provider (Refuser).
enum CancelledBy { client, prestataire }

/// A user account. Providers additionally have a [Provider] profile with the same id.
class AppUser {
  AppUser({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.passwordHash,
    required this.role,
    this.addresses = const [],
    this.notifyRequests = true,
    this.notifyPromos = false,
  });

  final String id;
  String name;
  String phone;
  String? email;
  final String passwordHash;
  Role? role; // null until the account type is chosen (screen 4)
  List<SavedAddress> addresses;
  bool notifyRequests;
  bool notifyPromos;

  String get firstName => name.trim().split(' ').first;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
    'passwordHash': passwordHash,
    'role': role?.name,
    'addresses': addresses.map((a) => a.toJson()).toList(),
    'notifyRequests': notifyRequests,
    'notifyPromos': notifyPromos,
  };

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    id: j['id'],
    name: j['name'],
    phone: j['phone'],
    email: j['email'],
    passwordHash: j['passwordHash'],
    role: j['role'] == null ? null : Role.values.byName(j['role']),
    addresses: [for (final a in (j['addresses'] as List? ?? [])) SavedAddress.fromJson(a)],
    notifyRequests: j['notifyRequests'] ?? true,
    notifyPromos: j['notifyPromos'] ?? false,
  );
}

class SavedAddress {
  SavedAddress({required this.label, required this.line, required this.commune, required this.wilaya});
  String label; // "Domicile", "Parents"
  String line;
  String commune;
  String wilaya;

  String get short => '$commune, $wilaya';
  String get full => '$line, $commune, $wilaya';

  Map<String, dynamic> toJson() => {'label': label, 'line': line, 'commune': commune, 'wilaya': wilaya};
  factory SavedAddress.fromJson(Map<String, dynamic> j) =>
      SavedAddress(label: j['label'], line: j['line'], commune: j['commune'], wilaya: j['wilaya']);
}

/// One priced service on a provider profile, in Algerian dinars.
class ServiceRate {
  ServiceRate({required this.name, required this.priceDa});
  String name;
  int priceDa;

  Map<String, dynamic> toJson() => {'name': name, 'priceDa': priceDa};
  factory ServiceRate.fromJson(Map<String, dynamic> j) => ServiceRate(name: j['name'], priceDa: j['priceDa']);
}

/// A provider ("prestataire") profile.
class Provider {
  Provider({
    required this.id,
    required this.name,
    required this.phone,
    required this.category,
    required this.wilaya,
    required this.commune,
    this.coverage = const [],
    this.bio = '',
    this.yearsExperience = 0,
    this.services = const [],
    this.photo,
    this.verified = false,
    this.available = true,
    this.availableWeekend = false,
    this.urgent = false,
    this.suspended = false,
  });

  final String id;
  String name;
  String phone;
  Category category;
  String wilaya;
  String commune;

  /// Extra communes covered, besides [commune].
  List<String> coverage;
  String bio;
  int yearsExperience;
  List<ServiceRate> services;

  /// Either an asset path ("assets/...") or base64 JPEG bytes uploaded by the provider.
  String? photo;
  bool verified;
  bool available; // available today
  bool availableWeekend;
  bool urgent; // takes emergencies

  /// Set by an admin: hidden from search and can't receive new requests.
  bool suspended;

  /// Lowest service price: the "à partir de" price on cards.
  int get fromPrice => services.isEmpty ? 0 : services.map((s) => s.priceDa).reduce((a, b) => a < b ? a : b);

  String get initials => name.trim().split(RegExp(r'\s+')).take(2).map((p) => p[0]).join().toUpperCase();

  /// Share of the profile that is filled in, for the dashboard bar (screen 16).
  double get completion {
    var done = 0;
    if (photo != null) done++;
    if (bio.trim().length >= 30) done++;
    if (services.isNotEmpty) done++;
    if (coverage.isNotEmpty) done++;
    if (yearsExperience > 0) done++;
    return (3 + done) / 8; // name, phone and trade are always set
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'category': category.name,
    'wilaya': wilaya,
    'commune': commune,
    'coverage': coverage,
    'bio': bio,
    'yearsExperience': yearsExperience,
    'services': services.map((s) => s.toJson()).toList(),
    'photo': photo,
    'verified': verified,
    'available': available,
    'availableWeekend': availableWeekend,
    'urgent': urgent,
    'suspended': suspended,
  };

  factory Provider.fromJson(Map<String, dynamic> j) => Provider(
    id: j['id'],
    name: j['name'],
    phone: j['phone'],
    category: Category.byName(j['category']),
    wilaya: j['wilaya'],
    commune: j['commune'],
    coverage: List<String>.from(j['coverage'] ?? const []),
    bio: j['bio'] ?? '',
    yearsExperience: j['yearsExperience'] ?? 0,
    services: [for (final s in (j['services'] as List? ?? [])) ServiceRate.fromJson(s)],
    photo: j['photo'],
    verified: j['verified'] ?? false,
    available: j['available'] ?? true,
    availableWeekend: j['availableWeekend'] ?? false,
    urgent: j['urgent'] ?? false,
    suspended: j['suspended'] ?? false,
  );
}

class ServiceRequest {
  ServiceRequest({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.clientPhone,
    required this.providerId,
    required this.service,
    required this.description,
    required this.address,
    required this.scheduledAt,
    required this.createdAt,
    this.photo,
    this.status = RequestStatus.enAttente,
    this.cancelledBy,
    this.reviewed = false,
  });

  final String id;
  final String clientId;
  final String clientName;
  final String clientPhone;
  final String providerId;
  final String service;
  final String description;
  final String address;
  final DateTime scheduledAt;
  final DateTime createdAt;

  /// Optional problem photo, base64 JPEG.
  final String? photo;
  RequestStatus status;
  CancelledBy? cancelledBy;
  bool reviewed;

  /// "Refusée" is shown as a note on an Annulée request, so the spec's 4 badges stay.
  bool get refused => status == RequestStatus.annulee && cancelledBy == CancelledBy.prestataire;

  Map<String, dynamic> toJson() => {
    'id': id,
    'clientId': clientId,
    'clientName': clientName,
    'clientPhone': clientPhone,
    'providerId': providerId,
    'service': service,
    'description': description,
    'address': address,
    'scheduledAt': scheduledAt.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'photo': photo,
    'status': status.name,
    'cancelledBy': cancelledBy?.name,
    'reviewed': reviewed,
  };

  factory ServiceRequest.fromJson(Map<String, dynamic> j) => ServiceRequest(
    id: j['id'],
    clientId: j['clientId'],
    clientName: j['clientName'],
    clientPhone: j['clientPhone'],
    providerId: j['providerId'],
    service: j['service'],
    description: j['description'],
    address: j['address'],
    scheduledAt: DateTime.parse(j['scheduledAt']),
    createdAt: DateTime.parse(j['createdAt']),
    photo: j['photo'],
    status: RequestStatus.byName(j['status']),
    cancelledBy: j['cancelledBy'] == null ? null : CancelledBy.values.byName(j['cancelledBy']),
    reviewed: j['reviewed'] ?? false,
  );
}

class Review {
  Review({
    required this.id,
    required this.providerId,
    required this.authorName,
    required this.stars,
    required this.comment,
    required this.createdAt,
    this.requestId,
    this.authorId,
    this.hidden = false,
    this.moderated = false,
  });

  final String id;
  final String providerId;
  final String? requestId;
  final String? authorId;
  final String authorName;
  final int stars; // 1..5
  final String comment;
  final DateTime createdAt;

  /// Hidden by an admin (moderation): not shown and not counted in the rating.
  bool hidden;

  /// An admin has looked at it (kept or hidden), so it leaves the moderation queue.
  bool moderated;

  Map<String, dynamic> toJson() => {
    'id': id,
    'providerId': providerId,
    'requestId': requestId,
    'authorId': authorId,
    'authorName': authorName,
    'stars': stars,
    'comment': comment,
    'createdAt': createdAt.toIso8601String(),
    'hidden': hidden,
    'moderated': moderated,
  };

  factory Review.fromJson(Map<String, dynamic> j) => Review(
    id: j['id'],
    providerId: j['providerId'],
    requestId: j['requestId'],
    authorId: j['authorId'],
    authorName: j['authorName'],
    stars: j['stars'],
    comment: j['comment'],
    createdAt: DateTime.parse(j['createdAt']),
    hidden: j['hidden'] ?? false,
    moderated: j['moderated'] ?? false,
  );
}

/// Average and 5→1 star counts for a provider (screen 19).
class RatingSummary {
  RatingSummary(List<Review> reviews)
    : count = reviews.length,
      average = reviews.isEmpty ? 0 : reviews.map((r) => r.stars).reduce((a, b) => a + b) / reviews.length,
      byStars = {for (var s = 5; s >= 1; s--) s: reviews.where((r) => r.stars == s).length};
  final int count;
  final double average;
  final Map<int, int> byStars;
}

/// Wilayas and communes used in the MVP (Alger, Blida, Oran, Constantine, Tizi Ouzou).
const Map<String, List<String>> wilayas = {
  'Alger': ['Alger Centre', 'Bab Ezzouar', 'Hydra', 'Kouba', 'El Biar', 'Bir Mourad Raïs', 'Chéraga', 'Dar El Beïda', 'Bordj El Kiffan', 'Ben Aknoun'],
  'Blida': ['Blida', 'Boufarik', 'Ouled Yaïch', 'Beni Mered'],
  'Oran': ['Oran', 'Bir El Djir', 'Es Sénia'],
  'Constantine': ['Constantine', 'El Khroub', 'Ali Mendjeli'],
  'Tizi Ouzou': ['Tizi Ouzou', 'Draâ Ben Khedda', 'Azazga'],
};

String wilayaOf(String commune) => wilayas.entries.firstWhere((e) => e.value.contains(commune), orElse: () => wilayas.entries.first).key;
