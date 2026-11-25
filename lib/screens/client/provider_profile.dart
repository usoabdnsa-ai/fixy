import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart' hide Provider;

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../util/format.dart';
import '../../util/native.dart';
import '../../widgets/icons.dart';
import '../../widgets/kit.dart';
import '../shared/provider_reviews.dart';
import '../shared/router.dart';
import 'request_form.dart';

/// Screen 9: photo, verified badge, rating, phone number card, bio, DA rates,
/// reviews, sticky "Appeler" and "Demander un service".
class ProviderProfileScreen extends StatelessWidget {
  const ProviderProfileScreen({super.key, required this.providerId, this.preview = false});
  final String providerId;

  /// The provider looking at their own public profile: no call/request bar.
  final bool preview;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = s.providers.byId(providerId);
    if (p == null) return const Scaffold(body: Center(child: Text('Artisan introuvable.')));
    final r = s.rating(p.id);
    final reviews = s.reviews.forProvider(p.id);
    final fav = s.isFavorite(p.id);
    final isClient = s.user?.role == Role.client;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: C.navy,
            foregroundColor: C.white,
            surfaceTintColor: Colors.transparent,
            title: Text(preview ? 'Mon profil public' : p.name, style: title(size: 18, color: C.white)),
            actions: [
              if (isClient)
                IconButton(
                  tooltip: fav ? 'Retirer des favoris' : 'Ajouter aux favoris',
                  icon: Icon(fav ? PhosphorIconsFill.heart : PhosphorIconsBold.heart, color: fav ? const Color(0xFFFF6B6F) : C.white),
                  onPressed: () async {
                    final added = await s.toggleFavorite(p.id);
                    if (context.mounted) toast(context, added ? 'Ajouté aux favoris' : 'Retiré des favoris');
                  },
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Stack(
              children: [
                Container(
                  height: 64,
                  decoration: const BoxDecoration(
                    color: C.navy,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(S.gutter, 8, S.gutter, S.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(child: Avatar(photo: p.photo, size: 108, ring: true)),
                      const SizedBox(height: S.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(p.name, textAlign: TextAlign.center, style: title(size: 24)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${p.category.label} · ${p.commune}, ${p.wilaya}',
                        textAlign: TextAlign.center,
                        style: body(color: C.inkSoft),
                      ),
                      const SizedBox(height: S.md),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (p.verified) const VerifiedBadge(),
                          _Tag(icon: PhosphorIconsBold.briefcase, text: '${plural(p.yearsExperience, 'an')} d’expérience'),
                          if (p.urgent) const _Tag(icon: PhosphorIconsBold.lightning, text: 'Urgences'),
                          if (p.availableWeekend) const _Tag(icon: PhosphorIconsBold.calendarBlank, text: 'Week-end'),
                        ],
                      ),
                      const SizedBox(height: S.lg),
                      Rise(
                        child: _StatsRow(
                          p: p,
                          r: r,
                          onReviews: () => push(context, ProviderReviewsScreen(providerId: p.id)),
                        ),
                      ),
                      const SizedBox(height: S.md),
                      Rise(index: 1, child: _PhoneCard(p.phone)),
                      const SizedBox(height: S.xl),
                      Text('À propos', style: title(size: 18)),
                      const SizedBox(height: S.sm),
                      Text(p.bio.isEmpty ? 'Cet artisan n’a pas encore ajouté de description.' : p.bio, style: body(color: p.bio.isEmpty ? C.inkSoft : C.ink)),
                      if (p.coverage.isNotEmpty) ...[
                        const SizedBox(height: S.md),
                        Text('Intervient aussi à : ${p.coverage.join(', ')}', style: body(size: 14, color: C.inkSoft)),
                      ],
                      const SizedBox(height: S.xl),
                      Text('Tarifs indicatifs', style: title(size: 18)),
                      const SizedBox(height: S.sm),
                      AppCard(
                        padding: const EdgeInsets.symmetric(horizontal: S.lg, vertical: S.sm),
                        child: Column(
                          children: [
                            for (final (i, sv) in p.services.indexed) ...[
                              if (i > 0) const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(sv.name, style: body(size: 14.5, weight: FontWeight.w500)),
                                    ),
                                    Text(da(sv.priceDa), style: figs(size: 15, weight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ],
                            if (p.services.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(S.md),
                                child: Text('Aucun tarif renseigné.', style: body(color: C.inkSoft)),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: S.sm),
                      Text(
                        'Prix indicatifs, à confirmer par téléphone. Le paiement se fait directement avec l’artisan.',
                        style: body(size: 12.5, color: C.inkSoft),
                      ),
                      const SizedBox(height: S.xl),
                      SectionHeader(
                        'Avis clients',
                        action: reviews.isEmpty ? null : 'Tout voir (${reviews.length})',
                        onAction: () => push(context, ProviderReviewsScreen(providerId: p.id)),
                      ),
                      if (reviews.isEmpty)
                        Text('Pas encore d’avis.', style: body(color: C.inkSoft))
                      else
                        for (final rv in reviews.take(3))
                          Padding(
                            padding: const EdgeInsets.only(bottom: S.md),
                            child: ReviewCard(rv),
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: preview || !isClient
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(S.gutter, S.md, S.gutter, S.md),
                decoration: const BoxDecoration(
                  color: C.card,
                  border: Border(top: BorderSide(color: C.line)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Btn.accent('Appeler', icon: PhosphorIconsBold.phone, onTap: () => callPhone(context, p.phone)),
                    ),
                    const SizedBox(width: S.sm),
                    Expanded(
                      flex: 6,
                      child: Btn('Demander un service', onTap: () => push(context, RequestFormScreen(provider: p))),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: C.card,
      borderRadius: BorderRadius.circular(R.pill),
      border: Border.all(color: C.line),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: C.inkSoft),
        const SizedBox(width: 4),
        Text(
          text,
          style: body(size: 12.5, weight: FontWeight.w600, color: C.inkSoft),
        ),
      ],
    ),
  );
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.p, required this.r, required this.onReviews});
  final Provider p;
  final RatingSummary r;
  final VoidCallback onReviews;
  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(vertical: S.lg),
    child: IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: Pressable(
              onTap: onReviews,
              semanticLabel: 'Voir les avis',
              child: _Stat(top: r.count == 0 ? '–' : rating1(r.average), bottom: '${r.count} avis', star: true),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: _Stat(top: da(p.fromPrice), bottom: 'à partir de'),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: _Stat(top: '${p.yearsExperience} ans', bottom: 'd’expérience'),
          ),
        ],
      ),
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.top, required this.bottom, this.star = false});
  final String top, bottom;
  final bool star;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (star) ...[const Icon(PhosphorIconsFill.star, size: 17, color: C.star), const SizedBox(width: 3)],
          Text(top, style: figs(size: 17, weight: FontWeight.w800)),
        ],
      ),
      const SizedBox(height: 2),
      Text(bottom, style: body(size: 12.5, color: C.inkSoft)),
    ],
  );
}

/// The direct phone number card (spec Rule A).
class _PhoneCard extends StatelessWidget {
  const _PhoneCard(this.phone);
  final String phone;
  @override
  Widget build(BuildContext context) => AppCard(
    color: C.turqWash,
    border: true,
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        const IconTile(icon: PhosphorIconsBold.phone, color: C.navy, wash: C.turq, size: 44),
        const SizedBox(width: S.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Numéro direct', style: body(size: 13, color: C.inkSoft)),
              Text(phoneFmt(phone), style: figs(size: 19, weight: FontWeight.w800)),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Copier le numéro',
          icon: const Icon(PhosphorIconsBold.clipboardText, size: 20, color: C.navy),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: phone));
            toast(context, 'Numéro copié');
          },
        ),
      ],
    ),
  );
}
