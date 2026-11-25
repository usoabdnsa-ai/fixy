import '../data/local_store.dart';
import '../data/models.dart';
import 'auth_service.dart';

enum SortBy {
  recommended('Recommandés'),
  rating('Mieux notés'),
  priceAsc('Prix croissant'),
  priceDesc('Prix décroissant'),
  experience('Plus expérimentés');

  const SortBy(this.label);
  final String label;
}

/// Everything the search and filter screens (7–8) can ask for.
class ProviderQuery {
  const ProviderQuery({
    this.text = '',
    this.category,
    this.wilaya,
    this.communes = const {},
    this.minRating = 0,
    this.maxPrice,
    this.availableToday = false,
    this.weekend = false,
    this.urgent = false,
    this.sort = SortBy.recommended,
  });

  final String text;
  final Category? category;
  final String? wilaya;
  final Set<String> communes;
  final double minRating;
  final int? maxPrice;
  final bool availableToday, weekend, urgent;
  final SortBy sort;

  /// Number of active filters, for the badge on the filter button.
  int get activeCount =>
      (wilaya != null ? 1 : 0) +
      (communes.isNotEmpty ? 1 : 0) +
      (minRating > 0 ? 1 : 0) +
      (maxPrice != null ? 1 : 0) +
      (availableToday ? 1 : 0) +
      (weekend ? 1 : 0) +
      (urgent ? 1 : 0);

  ProviderQuery copyWith({
    String? text,
    Category? Function()? category,
    String? Function()? wilaya,
    Set<String>? communes,
    double? minRating,
    int? Function()? maxPrice,
    bool? availableToday,
    bool? weekend,
    bool? urgent,
    SortBy? sort,
  }) => ProviderQuery(
    text: text ?? this.text,
    category: category != null ? category() : this.category,
    wilaya: wilaya != null ? wilaya() : this.wilaya,
    communes: communes ?? this.communes,
    minRating: minRating ?? this.minRating,
    maxPrice: maxPrice != null ? maxPrice() : this.maxPrice,
    availableToday: availableToday ?? this.availableToday,
    weekend: weekend ?? this.weekend,
    urgent: urgent ?? this.urgent,
    sort: sort ?? this.sort,
  );

  /// Same text, trade and sort; filters cleared.
  ProviderQuery cleared() => ProviderQuery(text: text, category: category, sort: sort);
}

abstract class ProviderService {
  List<Provider> get all;
  Provider? byId(String id);
  List<Provider> search(ProviderQuery q, double Function(String providerId) rating);
  Future<void> save(Provider p);
}

class LocalProviderService implements ProviderService {
  LocalProviderService(this._store) {
    _items = [for (final j in _store.readList(StoreKeys.providers)) Provider.fromJson(j)];
  }

  final LocalStore _store;
  late List<Provider> _items;

  @override
  List<Provider> get all => List.unmodifiable(_items);

  @override
  Provider? byId(String id) {
    for (final p in _items) {
      if (p.id == id) return p;
    }
    return null;
  }

  static String _fold(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[àâä]'), 'a')
      .replaceAll(RegExp('[îï]'), 'i')
      .replaceAll(RegExp('[ôö]'), 'o')
      .replaceAll(RegExp('[ùûü]'), 'u')
      .replaceAll('ç', 'c');

  @override
  List<Provider> search(ProviderQuery q, double Function(String providerId) rating) {
    final t = _fold(q.text.trim());
    final out = _items.where((p) {
      if (q.category != null && p.category != q.category) return false;
      if (t.isNotEmpty) {
        final hay = _fold([p.name, p.category.label, p.category.domain, p.commune, p.wilaya, ...p.services.map((s) => s.name)].join(' '));
        if (!t.split(RegExp(r'\s+')).every(hay.contains)) return false;
      }
      if (q.wilaya != null && p.wilaya != q.wilaya) return false;
      if (q.communes.isNotEmpty && !q.communes.contains(p.commune) && !p.coverage.any(q.communes.contains)) return false;
      if (q.minRating > 0 && rating(p.id) < q.minRating) return false;
      if (q.maxPrice != null && p.fromPrice > q.maxPrice!) return false;
      if (q.availableToday && !p.available) return false;
      if (q.weekend && !p.availableWeekend) return false;
      if (q.urgent && !p.urgent) return false;
      return true;
    }).toList();

    int byRating(Provider a, Provider b) => rating(b.id).compareTo(rating(a.id));
    switch (q.sort) {
      case SortBy.recommended:
        // Verified and available first, then by rating.
        int score(Provider p) => (p.verified ? 2 : 0) + (p.available ? 1 : 0);
        out.sort((a, b) {
          final s = score(b).compareTo(score(a));
          return s != 0 ? s : byRating(a, b);
        });
      case SortBy.rating:
        out.sort(byRating);
      case SortBy.priceAsc:
        out.sort((a, b) => a.fromPrice.compareTo(b.fromPrice));
      case SortBy.priceDesc:
        out.sort((a, b) => b.fromPrice.compareTo(a.fromPrice));
      case SortBy.experience:
        out.sort((a, b) => b.yearsExperience.compareTo(a.yearsExperience));
    }
    return out;
  }

  @override
  Future<void> save(Provider p) async {
    if (p.name.trim().length < 3) throw FixyException('Entrez votre nom complet.');
    if (!LocalAuthService.validPhone(p.phone)) throw FixyException('Numéro invalide. Exemple : 0550 12 34 56.');
    p.phone = LocalAuthService.normalizePhone(p.phone);
    for (final s in p.services) {
      if (s.name.trim().isEmpty) throw FixyException('Chaque service doit avoir un nom.');
      if (s.priceDa <= 0) throw FixyException('Le prix de « ${s.name} » doit être supérieur à 0 DA.');
    }
    final i = _items.indexWhere((x) => x.id == p.id);
    if (i == -1) {
      _items.add(p);
    } else {
      _items[i] = p;
    }
    await _store.writeList(StoreKeys.providers, _items.map((x) => x.toJson()).toList());
  }

  Future<void> addAll(List<Provider> ps) async {
    _items.addAll(ps);
    await _store.writeList(StoreKeys.providers, _items.map((x) => x.toJson()).toList());
  }
}
