import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart' hide Provider;

import '../../data/models.dart';
import '../../services/provider_service.dart';
import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/icons.dart';
import '../../widgets/kit.dart';
import '../shared/provider_card.dart';
import '../shared/router.dart';
import 'address_sheet.dart';
import 'categories.dart';
import 'filters.dart';
import 'results.dart';

/// Screen 5: greeting, location pill, search bar with filter button,
/// categories, popular artisans.
class ClientHome extends StatelessWidget {
  const ClientHome({super.key});

  ProviderQuery _base(AppState s) => ProviderQuery(wilaya: s.location?.wilaya);

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final popular = s.popular();
    final hour = DateTime.now().hour;
    final hello = hour < 5 || hour >= 18 ? 'Bonsoir' : 'Bonjour';
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: C.navy,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(S.gutter, S.md, S.gutter, S.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('$hello ${s.user?.firstName ?? ''}', style: title(size: 24, color: C.white)),
                                  const SizedBox(height: 2),
                                  Text('De quoi avez-vous besoin aujourd’hui ?', style: body(size: 14.5, color: const Color(0xFFB7C4D3))),
                                ],
                              ),
                            ),
                            const FixyMark(size: 40, onDark: true),
                          ],
                        ),
                        const SizedBox(height: S.lg),
                        _LocationPill(address: s.location, onTap: () => showAddressSheet(context)),
                        const SizedBox(height: S.md),
                        _SearchBar(
                          onSearch: () => push(context, ResultsScreen(initial: _base(s), autofocus: true)),
                          onFilter: () async {
                            final q = await push<ProviderQuery>(context, FiltersScreen(initial: _base(s)));
                            if (q != null && context.mounted) push(context, ResultsScreen(initial: q));
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(S.gutter, S.xl, S.gutter, 0),
              sliver: SliverToBoxAdapter(
                child: SectionHeader('Catégories', action: 'Tout voir', onAction: () => push(context, const CategoriesScreen())),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 100,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: S.gutter),
                  scrollDirection: Axis.horizontal,
                  itemCount: Category.values.length,
                  separatorBuilder: (_, _) => const SizedBox(width: S.md),
                  itemBuilder: (_, i) {
                    final c = Category.values[i];
                    return Rise(
                      index: i,
                      child: _CategoryChip(
                        c,
                        onTap: () => push(context, ResultsScreen(initial: _base(s).copyWith(category: () => c))),
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(S.gutter, S.xl, S.gutter, 0),
              sliver: SliverToBoxAdapter(
                child: SectionHeader(
                  'Artisans populaires',
                  action: 'Tout voir',
                  onAction: () => push(context, ResultsScreen(initial: _base(s).copyWith(sort: SortBy.rating))),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 232,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(S.gutter, 0, S.gutter, S.md),
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: popular.length,
                  separatorBuilder: (_, _) => const SizedBox(width: S.md),
                  itemBuilder: (_, i) => Rise(index: i, child: ProviderMiniCard(popular[i])),
                ),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(S.gutter, S.md, S.gutter, S.xl),
              sliver: SliverToBoxAdapter(child: _HowItWorks()),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationPill extends StatelessWidget {
  const _LocationPill({required this.address, required this.onTap});
  final SavedAddress? address;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    semanticLabel: 'Changer de localisation',
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: C.navySoft, borderRadius: BorderRadius.circular(R.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(PhosphorIconsFill.house, size: 15, color: C.turq),
          const SizedBox(width: 6),
          Text(
            address?.short ?? 'Choisir une adresse',
            style: body(size: 13.5, weight: FontWeight.w600, color: C.white),
          ),
          const SizedBox(width: 4),
          const Icon(PhosphorIconsBold.caretDown, size: 13, color: Color(0xFFB7C4D3)),
        ],
      ),
    ),
  );
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onSearch, required this.onFilter});
  final VoidCallback onSearch, onFilter;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Pressable(
          onTap: onSearch,
          scale: .98,
          semanticLabel: 'Rechercher un artisan',
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: C.white, borderRadius: BorderRadius.circular(R.md)),
            child: Row(
              children: [
                const Icon(PhosphorIconsBold.magnifyingGlass, size: 20, color: C.inkSoft),
                const SizedBox(width: S.md),
                Expanded(
                  child: Text(
                    'Plombier, électricien, peintre…',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: body(color: C.inkFaint),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(width: S.sm),
      Pressable(
        onTap: onFilter,
        semanticLabel: 'Filtres',
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: C.turq, borderRadius: BorderRadius.circular(R.md)),
          child: const Icon(PhosphorIconsBold.slidersHorizontal, color: C.navy, size: 22),
        ),
      ),
    ],
  );
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip(this.c, {required this.onTap});
  final Category c;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    semanticLabel: c.label,
    child: SizedBox(
      width: 76,
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(R.md), boxShadow: lift),
            child: Icon(c.icon, color: C.navy, size: 27),
          ),
          const SizedBox(height: 7),
          Text(
            c.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: body(size: 12.5, weight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();
  @override
  Widget build(BuildContext context) => AppCard(
    border: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Comment ça marche', style: title(size: 16)),
        const SizedBox(height: S.md),
        for (final (icon, t) in [
          (PhosphorIconsBold.magnifyingGlass, 'Choisissez un artisan selon les avis et les prix en DA.'),
          (PhosphorIconsBold.phoneCall, 'Appelez-le directement, ou envoyez une demande.'),
          (PhosphorIconsBold.star, 'Une fois le service terminé, laissez votre avis.'),
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                IconTile(icon: icon, size: 34),
                const SizedBox(width: S.md),
                Expanded(
                  child: Text(t, style: body(size: 14, color: C.inkSoft)),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
