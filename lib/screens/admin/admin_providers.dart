import 'package:flutter/material.dart';
import 'package:provider/provider.dart' hide Provider;

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../util/format.dart';
import '../../widgets/icons.dart';
import '../../widgets/kit.dart';
import '../client/provider_profile.dart';
import '../shared/router.dart';

enum _Filter { toVerify, verified, suspended, all }

/// Verify providers (gives the "Vérifié" badge), remove the badge,
/// suspend (hidden from search, no new requests) or reactivate.
class AdminProvidersScreen extends StatefulWidget {
  const AdminProvidersScreen({super.key});
  @override
  State<AdminProvidersScreen> createState() => _AdminProvidersScreenState();
}

class _AdminProvidersScreenState extends State<AdminProvidersScreen> {
  _Filter _filter = _Filter.toVerify;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final all = s.providers.all;
    bool keep(Provider p, _Filter f) => switch (f) {
      _Filter.toVerify => !p.verified && !p.suspended,
      _Filter.verified => p.verified && !p.suspended,
      _Filter.suspended => p.suspended,
      _Filter.all => true,
    };
    int count(_Filter f) => all.where((p) => keep(p, f)).length;
    final list = all.where((p) => keep(p, _filter)).toList()..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      appBar: AppBar(title: const Text('Prestataires')),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(S.gutter, S.xs, S.gutter, S.sm),
              children: [
                for (final (f, label) in [
                  (_Filter.toVerify, 'À vérifier'),
                  (_Filter.verified, 'Vérifiés'),
                  (_Filter.suspended, 'Suspendus'),
                  (_Filter.all, 'Tous'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: S.sm),
                    child: ChoicePill('$label (${count(f)})', selected: _filter == f, onTap: () => setState(() => _filter = f)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: EmptyState(
                      icon: _filter == _Filter.toVerify ? PhosphorIconsBold.sealCheck : PhosphorIconsBold.users,
                      title: _filter == _Filter.toVerify ? 'Tout est vérifié' : 'Aucun prestataire',
                      text: _filter == _Filter.toVerify ? 'Les nouveaux prestataires apparaîtront ici.' : 'Aucun prestataire dans cette liste.',
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(S.gutter, S.sm, S.gutter, S.xl),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: S.md),
                    itemBuilder: (_, i) => Rise(index: i, child: _ProviderCard(list[i])),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard(this.p);
  final Provider p;

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final rating = s.rating(p.id);
    final jobs = s.requests.forProvider(p.id).where((r) => r.status == RequestStatus.terminee).length;

    Future<void> verify(bool v) async {
      if (await attempt(context, () => s.setVerified(p.id, v)) && context.mounted) {
        toast(context, v ? '${p.name} est maintenant vérifié' : 'Badge retiré à ${p.name}');
      }
    }

    Future<void> suspend(bool v) async {
      if (v &&
          !await confirmDialog(
            context,
            title: 'Suspendre ${p.name} ?',
            text: 'Son profil sera masqué de la recherche et il ne pourra plus recevoir de nouvelles demandes. Vous pourrez le réactiver.',
            confirm: 'Suspendre',
            danger: true,
          )) {
        return;
      }
      if (!context.mounted) return;
      if (await attempt(context, () => s.setSuspended(p.id, v)) && context.mounted) {
        toast(context, v ? '${p.name} est suspendu' : '${p.name} est réactivé');
      }
    }

    return AppCard(
      border: true,
      padding: const EdgeInsets.all(14),
      onTap: () => push(context, ProviderProfileScreen(providerId: p.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Avatar(photo: p.photo, size: 48),
              const SizedBox(width: S.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            p.name,
                            overflow: TextOverflow.ellipsis,
                            style: body(size: 15.5, weight: FontWeight.w700),
                          ),
                        ),
                        if (p.verified && !p.suspended) ...[const SizedBox(width: 5), const VerifiedBadge(compact: true)],
                      ],
                    ),
                    Text('${p.category.label} · ${p.commune}, ${p.wilaya}', style: body(size: 13.5, color: C.inkSoft)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        RatingLine(rating, size: 13),
                        Text('  ·  ${plural(jobs, 'mission')}  ·  ${plural(p.yearsExperience, 'an')}', style: body(size: 13, color: C.inkSoft)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: S.md),
          _Checks(p),
          if (p.suspended) ...[
            const SizedBox(height: S.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: S.md, vertical: S.sm),
              decoration: BoxDecoration(color: C.redWash, borderRadius: BorderRadius.circular(R.sm)),
              child: Row(
                children: [
                  const Icon(PhosphorIconsBold.prohibit, size: 16, color: C.red),
                  const SizedBox(width: S.sm),
                  Expanded(
                    child: Text(
                      'Suspendu : masqué de la recherche',
                      style: body(size: 13, weight: FontWeight.w600, color: C.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: S.md),
          Row(
            children: [
              if (p.suspended)
                Expanded(
                  child: Btn('Réactiver', compact: true, icon: PhosphorIconsBold.arrowCounterClockwise, onTap: () => suspend(false)),
                )
              else ...[
                Expanded(
                  child: p.verified
                      ? Btn.outline('Retirer le badge', compact: true, onTap: () => verify(false))
                      : Btn.accent('Vérifier', compact: true, icon: PhosphorIconsBold.sealCheck, onTap: () => verify(true)),
                ),
                const SizedBox(width: S.sm),
                Expanded(
                  child: Btn.danger('Suspendre', compact: true, icon: PhosphorIconsBold.prohibit, onTap: () => suspend(true)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// What the admin looks at before giving the badge: is the profile complete?
class _Checks extends StatelessWidget {
  const _Checks(this.p);
  final Provider p;
  @override
  Widget build(BuildContext context) {
    final items = [
      ('Photo', p.photo != null),
      ('Description', p.bio.trim().length >= 30),
      ('Tarifs', p.services.isNotEmpty),
      ('Zone', p.coverage.isNotEmpty),
      ('Expérience', p.yearsExperience > 0),
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final (label, ok) in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: ok ? C.greenWash : C.bg,
              borderRadius: BorderRadius.circular(R.pill),
              border: ok ? null : Border.all(color: C.line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(ok ? PhosphorIconsBold.check : PhosphorIconsBold.x, size: 12, color: ok ? C.green : C.inkFaint),
                const SizedBox(width: 3),
                Text(
                  label,
                  style: body(size: 12, weight: FontWeight.w600, color: ok ? C.green : C.inkSoft, height: 1.2),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
