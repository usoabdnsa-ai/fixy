import 'package:fixy/data/local_store.dart';
import 'package:fixy/data/models.dart';
import 'package:fixy/data/seed.dart';
import 'package:fixy/services/auth_service.dart';
import 'package:fixy/services/favorite_service.dart';
import 'package:fixy/services/provider_service.dart';
import 'package:fixy/services/request_service.dart';
import 'package:fixy/services/review_service.dart';
import 'package:fixy/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppState s;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    s = await AppState.load();
  });

  Future<ServiceRequest> newRequest() async {
    await s.login(demoClientPhone, demoPassword);
    return s.createRequest(
      provider: s.providers.byId('p01')!,
      service: 'Diagnostic fuite',
      description: 'Fuite sous l’évier de la cuisine.',
      address: 'Cité 5 Juillet, Bab Ezzouar',
      scheduledAt: DateTime.now().add(const Duration(days: 1)),
    );
  }

  group('Comptes', () {
    test('inscription, choix du type, puis connexion avec le même mot de passe', () async {
      await s.register(name: 'Lina Benali', phone: '0770 12 34 56', password: 'secret1');
      expect(s.user!.role, isNull);
      await s.chooseRole(Role.client);
      await s.logout();
      await s.login('0770123456', 'secret1');
      expect(s.user!.name, 'Lina Benali');
      expect(s.user!.role, Role.client);
    });

    test('mauvais mot de passe refusé, mot de passe jamais stocké en clair', () async {
      expect(() => s.login(demoClientPhone, 'faux'), throwsA(isA<FixyException>()));
      expect(s.auth.byId('c01')!.passwordHash, isNot(contains(demoPassword)));
    });

    test('numéro invalide ou déjà utilisé refusé', () async {
      expect(() => s.register(name: 'Test User', phone: '0212345678', password: 'secret1'), throwsA(isA<FixyException>()));
      expect(() => s.register(name: 'Test User', phone: demoClientPhone, password: 'secret1'), throwsA(isA<FixyException>()));
    });
  });

  group('Cycle de vie d’une demande (4 statuts)', () {
    test('En attente → Acceptée → Terminée → avis unique', () async {
      final r = await newRequest();
      expect(r.status, RequestStatus.enAttente);

      await s.logout();
      await s.login(demoProviderPhone, demoPassword);
      expect(s.incoming.map((x) => x.id), contains(r.id));
      await s.accept(r.id);
      expect(s.requests.byId(r.id)!.status, RequestStatus.acceptee);
      await s.finish(r.id);
      expect(s.requests.byId(r.id)!.status, RequestStatus.terminee);

      await s.logout();
      await s.login(demoClientPhone, demoPassword);
      final before = s.rating('p01').count;
      await s.addReview(s.requests.byId(r.id)!, 5, 'Parfait');
      expect(s.rating('p01').count, before + 1);
      expect(() => s.addReview(s.requests.byId(r.id)!, 4, 'Encore'), throwsA(isA<FixyException>()));
    });

    test('pas d’avis avant que le service soit terminé', () async {
      final r = await newRequest();
      expect(() => s.addReview(r, 5, 'Trop tôt'), throwsA(isA<FixyException>()));
    });

    test('refus du prestataire → Annulée (refusée), puis plus rien n’est possible', () async {
      final r = await newRequest();
      await s.logout();
      await s.login(demoProviderPhone, demoPassword);
      await s.refuse(r.id);
      final after = s.requests.byId(r.id)!;
      expect(after.status, RequestStatus.annulee);
      expect(after.refused, isTrue);
      expect(() => s.accept(r.id), throwsA(isA<FixyException>()));
    });

    test('le client annule ; une demande terminée ne peut plus être annulée', () async {
      final r = await newRequest();
      await s.cancel(r.id);
      expect(s.requests.byId(r.id)!.status, RequestStatus.annulee);
      expect(() => s.cancel('r_demo1'), throwsA(isA<FixyException>())); // already Terminée
    });

    test('un prestataire ne peut pas accepter la demande d’un autre', () async {
      final r = await newRequest();
      await s.logout();
      await s.login('0771234503', demoPassword); // Sofiane, électricien
      expect(() => s.accept(r.id), throwsA(isA<FixyException>()));
    });

    test('date passée et description vide refusées', () async {
      await s.login(demoClientPhone, demoPassword);
      expect(
        () => s.createRequest(
          provider: s.providers.byId('p01')!,
          service: 'x',
          description: 'trop',
          address: 'Bab Ezzouar',
          scheduledAt: DateTime.now().add(const Duration(days: 1)),
        ),
        throwsA(isA<FixyException>()),
      );
      expect(
        () => s.createRequest(
          provider: s.providers.byId('p01')!,
          service: 'x',
          description: 'Une description assez longue',
          address: 'Bab Ezzouar',
          scheduledAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        throwsA(isA<FixyException>()),
      );
    });
  });

  group('Recherche et filtres', () {
    test('par métier, wilaya, note minimale et prix', () {
      final plombiersAlger = s.search(const ProviderQuery(category: Category.plombier, wilaya: 'Alger'));
      expect(plombiersAlger.every((p) => p.category == Category.plombier && p.wilaya == 'Alger'), isTrue);
      expect(plombiersAlger, isNotEmpty);

      final top = s.search(const ProviderQuery(minRating: 4.8));
      expect(top.every((p) => s.rating(p.id).average >= 4.8), isTrue);

      final cheap = s.search(const ProviderQuery(maxPrice: 1500));
      expect(cheap.every((p) => p.fromPrice <= 1500), isTrue);
    });

    test('recherche texte sans accents : "electricien hydra"', () {
      final r = s.search(const ProviderQuery(text: 'electricien hydra'));
      expect(r.map((p) => p.id), contains('p03'));
    });

    test('tri par prix croissant', () {
      final r = s.search(const ProviderQuery(sort: SortBy.priceAsc));
      for (var i = 1; i < r.length; i++) {
        expect(r[i - 1].fromPrice <= r[i].fromPrice, isTrue);
      }
    });
  });

  test('favoris : ajout puis retrait', () async {
    await s.login(demoClientPhone, demoPassword);
    expect(await s.toggleFavorite('p03'), isTrue);
    expect(s.isFavorite('p03'), isTrue);
    expect(await s.toggleFavorite('p03'), isFalse);
    expect(s.favoriteProviders, isEmpty);
  });

  test('les données survivent à un redémarrage (rechargement depuis le stockage)', () async {
    final r = await newRequest();
    await s.toggleFavorite('p05');
    final store = await LocalStore.open();
    // Fresh services over the same storage = the app after a restart.
    expect(LocalRequestService(store).byId(r.id)?.description, r.description);
    expect(LocalFavoriteService(store).idsFor('c01'), contains('p05'));
    expect(LocalAuthService(store).currentUser?.id, 'c01');
    expect(LocalProviderService(store).all.length, 14);
    expect(LocalReviewService(store).forProvider('p01'), isNotEmpty);
  });

  test('profil prestataire : prix à 0 refusé', () async {
    final p = s.providers.byId('p02')!;
    p.services = [ServiceRate(name: 'Test', priceDa: 0)];
    expect(() => s.saveProvider(p), throwsA(isA<FixyException>()));
  });

  group('Administration', () {
    test('seul un admin peut vérifier, suspendre ou modérer', () async {
      await s.login(demoClientPhone, demoPassword);
      await expectLater(s.setVerified('p14', true), throwsA(isA<FixyException>()));
      await expectLater(s.setSuspended('p01', true), throwsA(isA<FixyException>()));
      await expectLater(s.moderateReview('vp11_1', hidden: true), throwsA(isA<FixyException>()));
      expect(s.providers.byId('p14')!.verified, isFalse);
    });

    test('personne ne peut se donner le rôle admin à l’inscription', () async {
      await s.register(name: 'Pirate Test', phone: '0770 99 88 77', password: 'secret1');
      await expectLater(s.chooseRole(Role.admin), throwsA(isA<FixyException>()));
      expect(s.user!.role, isNull);
    });

    test('vérifier un prestataire lui donne le badge et le retire de la file', () async {
      await s.login(demoAdminPhone, demoPassword);
      expect(s.user!.role, Role.admin);
      expect(s.admin.toVerify.map((p) => p.id), containsAll(['p11', 'p14']));
      await s.setVerified('p14', true);
      expect(s.providers.byId('p14')!.verified, isTrue);
      expect(s.admin.toVerify.map((p) => p.id), isNot(contains('p14')));
    });

    test('un prestataire suspendu disparaît de la recherche et ne reçoit plus de demandes', () async {
      await s.login(demoAdminPhone, demoPassword);
      await s.setSuspended('p01', true);
      expect(s.search(const ProviderQuery(category: Category.plombier)).map((p) => p.id), isNot(contains('p01')));
      await s.logout();
      await expectLater(newRequest(), throwsA(isA<FixyException>()));
      await s.logout();
      await s.login(demoAdminPhone, demoPassword);
      await s.setSuspended('p01', false);
      expect(s.search(const ProviderQuery(category: Category.plombier)).map((p) => p.id), contains('p01'));
    });

    test('un avis masqué ne compte plus dans la note et quitte la file', () async {
      await s.login(demoAdminPhone, demoPassword);
      final low = s.admin.toModerate.firstWhere((r) => r.providerId == 'p11');
      final before = s.rating('p11').count;
      await s.moderateReview(low.id, hidden: true);
      expect(s.rating('p11').count, before - 1);
      expect(s.reviews.forProvider('p11').map((r) => r.id), isNot(contains(low.id)));
      expect(s.admin.toModerate.map((r) => r.id), isNot(contains(low.id)));
    });

    test('statistiques calculées sur les vraies données', () async {
      await s.login(demoAdminPhone, demoPassword);
      final st = s.admin.stats(DateTime.now());
      expect(st.clients, 1);
      expect(st.providers, 14);
      expect(st.requests, 5);
      expect(st.byStatus[RequestStatus.terminee], 2);
      expect(st.last7Days.length, 7);
    });
  });
}
