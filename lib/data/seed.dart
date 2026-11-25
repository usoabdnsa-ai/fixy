import '../services/auth_service.dart';
import 'models.dart';

/// First-launch demo data. Names, phone numbers and reviews are invented.
///
/// Demo accounts (password for all: fixy1234):
/// - Client: 0550 11 22 33 (Amine Haddad)
/// - Prestataire: 0661 23 45 01 (Karim Benali, plombier), and every other
///   provider below with their own phone number.
const demoPassword = 'fixy1234';
const demoClientPhone = '0550112233';
const demoProviderPhone = '0661234501';

class SeedData {
  SeedData(this.users, this.providers, this.reviews, this.requests);
  final List<AppUser> users;
  final List<Provider> providers;
  final List<Review> reviews;
  final List<ServiceRequest> requests;
}

SeedData buildSeed(DateTime now) {
  Provider p(String id, String name, String phone, Category c, String commune, int years, List<(String, int)> services, String bio,
          {bool verified = true, bool available = true, bool weekend = false, bool urgent = false, List<String> coverage = const []}) =>
      Provider(
        id: id,
        name: name,
        phone: phone,
        category: c,
        wilaya: wilayaOf(commune),
        commune: commune,
        coverage: coverage,
        yearsExperience: years,
        services: [for (final s in services) ServiceRate(name: s.$1, priceDa: s.$2)],
        bio: bio,
        verified: verified,
        available: available,
        availableWeekend: weekend,
        urgent: urgent,
      );

  final providers = [
    p('p01', 'Karim Benali', '0661234501', Category.plombier, 'Bab Ezzouar', 12,
        [('Diagnostic fuite', 1500), ('Réparation robinet', 2000), ('Débouchage canalisation', 3500), ('Installation chauffe-eau', 6000)],
        'Plombier depuis 12 ans à Bab Ezzouar et environs. Fuites, débouchage, chauffe-eau. Je me déplace rapidement, devis clair avant de commencer.',
        urgent: true, weekend: true, coverage: ['Dar El Beïda', 'Bordj El Kiffan']),
    p('p02', 'Yacine Meziani', '0661234502', Category.plombier, 'Kouba', 7,
        [('Diagnostic fuite', 1200), ('Changement mitigeur', 2500), ('Débouchage', 3000)],
        'Travail propre et soigné, spécialisé salle de bain et cuisine.', coverage: ['Hydra', 'Alger Centre']),
    p('p03', 'Sofiane Kaci', '0771234503', Category.electricien, 'Hydra', 15,
        [('Diagnostic panne', 2000), ('Installation prise/interrupteur', 1500), ('Mise aux normes tableau', 12000)],
        'Électricien certifié, 15 ans d’expérience. Pannes, tableaux électriques, éclairage. Intervention d’urgence possible.',
        urgent: true, coverage: ['El Biar', 'Ben Aknoun', 'Bir Mourad Raïs']),
    p('p04', 'Nadir Hamdi', '0551234504', Category.electricien, 'Blida', 6,
        [('Diagnostic panne', 1500), ('Pose luminaire', 1800), ('Câblage pièce', 8000)],
        'Électricien à Blida, disponible aussi le week-end.', weekend: true, coverage: ['Boufarik', 'Beni Mered']),
    p('p05', 'Rachid Bouzid', '0661234505', Category.macon, 'Chéraga', 20,
        [('Réparation fissure', 4000), ('Pose carrelage (m²)', 1200), ('Petit muret', 15000)],
        'Maçon expérimenté : carrelage, fissures, petits travaux de rénovation. Devis gratuit sur place.'),
    p('p06', 'Mourad Saidi', '0771234506', Category.peintre, 'El Biar', 9,
        [('Peinture pièce (12 m²)', 9000), ('Retouches', 3000), ('Enduit + peinture (m²)', 700)],
        'Peinture intérieure et extérieure, finitions soignées, protection des meubles incluse.', weekend: true, coverage: ['Hydra']),
    p('p07', 'Lamia Cherif', '0551234507', Category.nettoyeur, 'Alger Centre', 5,
        [('Ménage appartement F3', 4000), ('Nettoyage après travaux', 8000), ('Vitres', 2500)],
        'Équipe de nettoyage sérieuse et ponctuelle. Produits fournis.', weekend: true, coverage: ['Kouba', 'El Biar']),
    p('p08', 'Hocine Larbi', '0661234508', Category.menuisier, 'Bir Mourad Raïs', 18,
        [('Réglage porte', 2000), ('Pose porte intérieure', 7000), ('Placard sur mesure', 45000)],
        'Menuisier bois et aluminium. Portes, placards, cuisines sur mesure.', coverage: ['Hydra', 'Kouba']),
    p('p09', 'Amine Touati', '0771234509', Category.climatisation, 'Bordj El Kiffan', 8,
        [('Entretien climatiseur', 2500), ('Recharge gaz', 5000), ('Installation split', 9000)],
        'Installation, entretien et dépannage de climatiseurs toutes marques.', urgent: true, weekend: true, coverage: ['Bab Ezzouar', 'Dar El Beïda']),
    p('p10', 'Farid Oukaci', '0551234510', Category.serrurier, 'Kouba', 11,
        [('Ouverture de porte', 3000), ('Changement serrure', 4500), ('Blindage', 35000)],
        'Serrurier disponible 7j/7 pour ouverture de porte et changement de serrure.', urgent: true, weekend: true, coverage: ['Alger Centre', 'Hydra']),
    p('p11', 'Bilal Ait Ali', '0661234511', Category.plombier, 'Oran', 4,
        [('Diagnostic fuite', 1000), ('Réparation chasse d’eau', 1800)],
        'Jeune plombier sérieux à Oran.', verified: false, available: false),
    p('p12', 'Samir Rahmani', '0771234512', Category.peintre, 'Constantine', 13,
        [('Peinture pièce (12 m²)', 8000), ('Décoration murale', 12000)],
        'Peinture et décoration à Constantine et Ali Mendjeli.', coverage: ['Ali Mendjeli', 'El Khroub']),
    p('p13', 'Djamel Ferhat', '0551234513', Category.electricien, 'Tizi Ouzou', 10,
        [('Diagnostic panne', 1500), ('Installation chauffage électrique', 6000)],
        'Électricien bâtiment à Tizi Ouzou.', available: false),
    p('p14', 'Kenza Belkacem', '0661234514', Category.nettoyeur, 'Bab Ezzouar', 3,
        [('Ménage appartement F3', 3500), ('Repassage (2 h)', 1500)],
        'Ménage à domicile, sérieuse et discrète.', verified: false, coverage: ['Dar El Beïda']),
  ];

  // Demo accounts. The demo client and every provider can log in with demoPassword.
  final hash = LocalAuthService.hash(demoPassword);
  final users = [
    AppUser(
      id: 'c01',
      name: 'Amine Haddad',
      phone: demoClientPhone,
      email: 'amine@exemple.dz',
      passwordHash: hash,
      role: Role.client,
      addresses: [
        SavedAddress(label: 'Domicile', line: 'Cité 5 Juillet, bât. 12, apt 4', commune: 'Bab Ezzouar', wilaya: 'Alger'),
        SavedAddress(label: 'Parents', line: '14 rue des Frères Bouadou', commune: 'Kouba', wilaya: 'Alger'),
      ],
    ),
    for (final pr in providers) AppUser(id: pr.id, name: pr.name, phone: pr.phone, passwordHash: hash, role: Role.prestataire),
  ];

  // Reviews: a few per provider, spread over the last months.
  const authors = ['Nassim B.', 'Sarah K.', 'Walid M.', 'Imane D.', 'Riad T.', 'Meriem A.', 'Hakim Z.', 'Lina F.', 'Omar S.', 'Yasmine H.'];
  const good = [
    'Très professionnel, ponctuel et travail propre. Je recommande.',
    'Rapide et efficace, prix correct.',
    'Problème réglé en une heure, merci !',
    'Bon contact, a bien expliqué le problème avant de commencer.',
    'Travail soigné, je referai appel à lui.',
  ];
  const mid = ['Bon travail mais un peu de retard.', 'Correct, prix un peu élevé.'];
  const low = ['Il a fallu repasser une deuxième fois.'];
  final pattern = <String, List<int>>{
    'p01': [5, 5, 4, 5, 5, 4, 5],
    'p02': [4, 5, 4, 3],
    'p03': [5, 5, 5, 4, 5],
    'p04': [4, 4, 5],
    'p05': [5, 4, 4, 5],
    'p06': [5, 4, 5],
    'p07': [5, 5, 4, 5],
    'p08': [5, 5, 4],
    'p09': [4, 5, 3, 5],
    'p10': [5, 4, 5, 5],
    'p11': [4, 2],
    'p12': [4, 5],
    'p13': [4],
    'p14': [],
  };
  var k = 0;
  final reviews = <Review>[
    for (final e in pattern.entries)
      for (final (i, s) in e.value.indexed)
        Review(
          id: 'v${e.key}_$i',
          providerId: e.key,
          authorName: authors[(k++) % authors.length],
          stars: s,
          comment: s >= 5 ? good[k % good.length] : (s == 4 ? good[(k + 2) % good.length] : (s == 3 ? mid[k % mid.length] : low[0])),
          createdAt: now.subtract(Duration(days: 4 + i * 17 + k % 9)),
        ),
  ];

  // A short history for the demo client, and incoming work for Karim (p01).
  DateTime at(int days, int hour) => DateTime(now.year, now.month, now.day + days, hour);
  final requests = [
    ServiceRequest(
      id: 'r_demo1', clientId: 'c01', clientName: 'Amine Haddad', clientPhone: demoClientPhone, providerId: 'p03',
      service: 'Diagnostic panne', description: 'Le disjoncteur saute dès que le chauffe-eau est allumé.',
      address: 'Cité 5 Juillet, bât. 12, apt 4, Bab Ezzouar, Alger', scheduledAt: at(-12, 10), createdAt: now.subtract(const Duration(days: 13)),
      status: RequestStatus.terminee,
    ),
    ServiceRequest(
      id: 'r_demo2', clientId: 'c01', clientName: 'Amine Haddad', clientPhone: demoClientPhone, providerId: 'p09',
      service: 'Entretien climatiseur', description: 'Entretien avant l’été, le split du salon fait du bruit.',
      address: 'Cité 5 Juillet, bât. 12, apt 4, Bab Ezzouar, Alger', scheduledAt: at(2, 15), createdAt: now.subtract(const Duration(days: 1)),
      status: RequestStatus.acceptee,
    ),
    ServiceRequest(
      id: 'r_demo3', clientId: 'u_demo_other', clientName: 'Sarah Kadri', clientPhone: '0770998877', providerId: 'p01',
      service: 'Débouchage canalisation', description: 'Évier de cuisine bouché, l’eau ne descend plus du tout.',
      address: '22 rue Hassiba Ben Bouali, Dar El Beïda, Alger', scheduledAt: at(1, 9), createdAt: now.subtract(const Duration(hours: 3)),
    ),
    ServiceRequest(
      id: 'r_demo4', clientId: 'u_demo_other2', clientName: 'Walid Mansouri', clientPhone: '0551443322', providerId: 'p01',
      service: 'Installation chauffe-eau', description: 'Remplacement de l’ancien chauffe-eau 50 L par un neuf (déjà acheté).',
      address: 'Lotissement 140, Bordj El Kiffan, Alger', scheduledAt: at(3, 14), createdAt: now.subtract(const Duration(days: 1, hours: 2)),
      status: RequestStatus.acceptee,
    ),
    ServiceRequest(
      id: 'r_demo5', clientId: 'u_demo_other3', clientName: 'Imane Djebbar', clientPhone: '0661778899', providerId: 'p01',
      service: 'Réparation robinet', description: 'Robinet de la salle de bain qui goutte en continu.',
      address: 'Cité AADL, Bab Ezzouar, Alger', scheduledAt: at(-6, 11), createdAt: now.subtract(const Duration(days: 8)),
      status: RequestStatus.terminee,
    ),
  ];

  return SeedData(users, providers, reviews, requests);
}
